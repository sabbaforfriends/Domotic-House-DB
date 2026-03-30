
set global log_bin_trust_function_creators = 1;

-- Operazione 1
/*
Il sistema di gestione della smart home genera suggerimenti di utilizzo dei dispositivi dipendentemente dalla disponibilità di energia rinnovabile
(es: energia disponibile ma non usata, congliato l'utilizzo al posto di immetterla nella rete generale).
I suggerimenti e le scelte degli utenti sono memorizzati nel database.
*/

drop event if exists suggerimento;
create event suggerimento
on schedule every 10 minute
starts '2021-10-20 00:00:00'
do
	call prova();

drop procedure if exists prova;
delimiter $$
create procedure prova()
begin
	declare potenza_minima double;
    declare potenza_disponibile double;
    declare durata_massima double;
    -- l'event viene eseguito ogni 10 minuti ma non so quanto ci mette a finire l'esecuzione quindi scelgo come istante di accensione del suggerimento al "blocco" successivo
    declare inizio timestamp default current_timestamp() + interval 10 minute;
    
    set potenza_minima = 	(select min(consumo) 
							from 	impostazioni
									natural join
                                    programma);
	-- ultima rilevazione potenza prodotta							
	set potenza_disponibile = 	(select	kW
								from	produzione
                                where	orario < inizio		-- riga non necessaria a regime ma per fini di test nel database sono presenti dati di produzione che fanno riferimento a momenti nel futuro
                                order by orario desc
                                limit 1);
	-- effettiva potenza disponibile
    set potenza_disponibile = potenza_disponibile - 	(select	if(count(*) = 0, 0, sum(consumo)/1000) as potenza_assorbita
														from 	storico
														where	inizio > orainizio
																and inizio < orafine);
	-- solo debug
	 #set potenza_disponibile  = 2000;
	
	-- se non ho abbastanza potenza da non poter neanche inziare un programma è inutile continuare
    if(potenza_minima < potenza_disponibile) then
		
	
    -- stima produzione delle 3 ore successive
    -- durata massima di un programma (serve per sapere quanto nel futuro devo stimare la produzione)
    set durata_massima = 	(select	max(durata)
							from 	impostazioni
									natural join
                                    programma);
	
    insert into suggerimento (dispositivo, impostazione, orario)
	with stima as (
	-- stima sulla potenza disponibile nei prossimi x minuti (dove x è la durata del programma più lungo)
	select	timestamp(makedate(year(current_date), dayofyear(current_date))) + interval hour(orario) hour + interval minute(orario) minute as orario,
			avg(kW) as potenza_disponibile
	from	produzione
	where	orario > inizio - interval 4 week
			and orario < inizio 			-- sempre stesso motivo di prima (dati nel futuro)
			and dayofweek(inizio) = dayofweek(orario)
			and hour(orario) between hour(inizio) and hour(inizio + interval durata_massima minute)
	group by hour(orario), minute(orario)
	), programmi as (
	-- programmi e le loro info
		select	codice, durata, consumo/1000 as  consumo
		from 	impostazioni
				natural join
				programma p
	), programmi_escludere as (
    -- programmi già accessi o in programma nell'intervallo di interesse
		select	*
        from 	storico 
        where	orainizio < inizio + interval durata_massima minute
				and orafine > inizio
                and impostazione  in 	(select	codice
										from 	programma)
	), programmi_target as (
		select	*
        from	programmi
        where	codice not in (select	*
								from 	programmi_escludere)
	), disponibile as (
	/* tolgo dalla previsione di produzione la potenza necessaria a mantenere accesi i dispositivi attualmente accesi (se non hanno un istante di fine li considero
	per tutto l'intervallo o i dispositivi impostati per una partenza differita)*/
		select	orario, if(sum(consumo) is null, potenza_disponibile, potenza_disponibile - sum(consumo)) as potenza_disponibile
		from 	stima st
				join
				storico so  
		where	so.orainizio <= st.orario
				and ( so.orafine >= st.orario
				or so.orafine is null )
		-- mi restano solo i record che hanno subito una modifica
	), disponibile2 as (
		-- ri joino con stima e modifico i record che ne hanno bisogno
		-- la nuova potenza disponibile potrebbe anche essere negativa se non sto producendo abbastanza e ho dispositivi accesi
		select	s.orario, if(d.potenza_disponibile is not null, if(d.potenza_disponibile < 0, 0, d.potenza_disponibile),s.potenza_disponibile) as potenza_disponibile
		from 	stima s
				left outer join
				disponibile d using(orario)
	), finale as (
		-- associo ad ogni istante di rilevamento produzione i programmi che avrebbero abbastanza potenza per restare accesi
		-- i calcoli su durata fanno "tornare" il valore 'controllo' anche per i programmi che non durano un multiplo di 10 minuti (continua a non funzionare bene se la durata non finisce con un 5 o uno 0)
		select	codice, count(*) as volte, if(durata < 10 or (durata/10)/(floor(durata/10)) <> 1, durata/10 + 0.5, durata/10) as controllo, durata, consumo
		from	programmi p
				join
				disponibile2 s
		where	orario > inizio
				-- durata + 5: senza il +5 i programmi che durano meno di 10 minuti non fanno join e non risultano quindi suggeribili
				and durata + 5 >= timestampdiff(minute, inizio, orario)
				and potenza_disponibile >= consumo
		group by codice
		order by orario
	), scelta as (
		-- i programmi disponibili scelgo quello con il consumo totale maggiore
		select	codice as programma, durata*consumo as fattore
		from 	finale 
		where	volte = controllo
	)
    select	*
    from 	finale;
    
	/*	select	u.dispositivo, s.programma, current_timestamp()
		from 	scelta s
				inner join
				utilizzabili u on u.impostazione = s.programma
		where	s.fattore = (select	max(t.fattore)
							from scelta t)
		limit 1;*/
	end if;
end $$
delimiter ;

-- call prova();

-- Operazione 2
/*
	Il database è inoltre dotato di una funzione di back-end, da implementare, 
    capace di stimare i consumi derivanti da una determinata impostazione relativa a un elemento di condizionamento per un dato giorno, 
    in base anche alla considerazione (o alla stima) dell’energia prodotta.
    
    
	ipotizziamo una durata non eccessiva e di avere a disposizione la temperatura media esterna
*/


delimiter ;
drop procedure if exists stima_condizionamento;
delimiter $$
create procedure stima_condizionamento	(IN _dispositivo integer, 
										IN _temperatura_esterna double, 
                                        IN _temperatura_target double, 
                                        IN _inizio timestamp, 
                                        IN _fine timestamp,
                                        OUT consumo_ double,
                                        OUT produzione_ double)
begin 
	declare dispersione double default (select livellodispersione from contratto);
	declare potenza_media double;
	declare coefficiente double default 0;
    declare COP double default 0;
    declare superficie double;
    declare riscaldamento boolean;

	-- consumo
    if _temperatura_esterna > _temperatura_target then
		set riscaldamento = false;
		set coefficiente = 	(select	valore
							from 	specifiche s
									inner join
									possiede p on s.nome = p.specifica
							where	dispositivo = _dispositivo
									and nome = 'EER');
    else
		set riscaldamento = true;
		set coefficiente = 	(select	valore
							from 	specifiche s
									inner join
									possiede p on s.nome = p.specifica
							where	dispositivo = _dispositivo
									and nome = 'COP');
    end if;
    
    set superficie = 	(select	(lunghezza+larghezza)*altezza
						from 	dispositivo d
								inner join 
                                smartplug sm on sm.codice = d.codicepresa
                                inner join
                                stanza st on st.codice = sm.codicestanza
						where	d.codice = _dispositivo);
    -- potenza termica
    set potenza_media = dispersione*(_temperatura_esterna - _temperatura_target)*superficie;
    if potenza_media < 0 then 
		set potenza_media = potenza_media * -1;
    end if;
    
    
    -- potenza elettrica
    set potenza_media = potenza_media / coefficiente;
    set potenza_media = floor(potenza_media * (timestampdiff(second, _inizio, _fine)/3600));
    
    
    -- produzione (o stima)
    -- controllo se il periodo è nel futuro o nel passato
    if _inizio > current_timestamp() then
    -- stima produzione
		with media as (
			select	timestamp(makedate(year(_inizio), dayofyear(_fine))) + interval timestampdiff(second, _inizio, _fine) second,
					avg(kW) as potenza_disponibile
			from	produzione
			where	orario > _inizio - interval 4 week
					and orario < _inizio 				-- (dati nel futuro)
					and dayofweek(_inizio) = dayofweek(orario)
					and hour(orario) between hour(_inizio) and hour(_inizio + interval timestampdiff(minute, _inizio, _fine) minute)
			group by hour(orario), minute(orario)
		) 
        select	potenza_media, floor(avg(potenza_disponibile)*1000*(timestampdiff(second, _inizio, _fine))/3600)
			into consumo_, produzione_
        from 	media;
   else
    -- recupero i dati che già ho
		select	potenza_media, floor(avg(kW)*1000*(timestampdiff(second, _inizio, _fine))/3600) 
			into consumo_, produzione_
        from 	produzione
        where	orario >= _inizio
				and orario <= _fine;
    end if;
  
end $$
delimiter ;


/*
set @output1 = 0;
set @output2 = 0;
call stima_condizionamento(2, 35, 20, current_timestamp(), current_timestamp() + interval 200 minute, @output1, @output2);
select @output1 as consumo, @output2 as produzione;
*/




-- Operazione 3
/*
	Classifica della giornata dei dispostivi (nome) più utilizzati
*/

drop procedure if exists Classifica_utilizzo;
delimiter $$
create procedure Classifica_utilizzo()
begin
	with bho as (
	select	dispositivo, orainizio, if(ifnull(orafine, current_timestamp()) > current_timestamp(), current_timestamp(), orafine) as orafine
	from 	storico
	where	dayofyear(orainizio) = dayofyear(current_date())
			and year(orainizio) = year(current_date())
            and orainizio < current_timestamp()
	), bho2 as (
		select	dispositivo, sum(timestampdiff(minute, orainizio, orafine)) as tempo
		from 	bho
		group by dispositivo
	)
	select	dispositivo, nome, rank() over(order by tempo desc) as Posizione
	from 	bho2
			inner join
            dispositivo on dispositivo.codice = bho2.dispositivo;
end $$
delimiter ;

#call Classifica_utilizzo();

-- Operazione 4
/*
	ultimo utente che ha interagito con un dispositivo e il suo nome(del dispositivo)
*/
drop procedure if exists ultimo_utilizzatore;
delimiter $$
create procedure ultimo_utilizzatore (in _dispositivo integer)
begin
	select 	nome as "Nome dispositivo" , ultimoutilizzatore as "Ultimo utilizzatore"
	from 	dispositivo
	where 	codice=_dispositivo;
end $$
delimiter ;

-- call ultimo_utilizzatore(8);



-- Operazione 5
/*
	consumo per fascia oraria, prendendo la media di un mese dato come input
*/

drop procedure if exists consumo_mese;
delimiter $$
create procedure consumo_mese(IN _mese integer, IN _anno integer)
begin

	declare	fascia integer;
    declare utente varchar(30);
    declare dispo integer;
    declare impost integer;
    declare consum double;
    
    declare inizio_int timestamp;
    declare fine_int timestamp;
    
    declare inizio_f integer;
    declare fine_f integer;
    
    declare fascia_fine integer;
    
    
    declare finito integer default 0;

	declare interazioni cursor for
		select	s.fasciaoraria, s.account, s.dispositivo, s.impostazione, s.orainizio, s.orafine, b.orainizio, b.orafine, s.Consumo
		from	storico s
				inner join
				bilancio b using(fasciaoraria)
		where	year(s.orainizio) = _anno
				and month(s.orainizio) = _mese
				and s.orainizio < current_timestamp;

	declare continue handler for not found
		set finito = 1;
    
	-- ad ogni interazione viene associata la fascia oraria in cui viene attivato un dispositivo ma questo non impedisce di lasciare acceso il dispositivo in intervalli di tempo che intersecano più fascie orarie
    -- questa tabela verrà usata per duplicare i record che sforano assegnandoli anche una nuova fascia oraria e "spezzando" l'interazione in interazioni che iniziano e finiscono nella stessa fascia oraria
	drop table if exists div_fascia;
	create temporary table div_fascia(
		fasciaoraria  integer not null,
		account varchar(30) not null,
		dispositivo integer not null,
		impostazione integer not null,
		orainizio timestamp not null,
		orafine timestamp not null,
        consumo double
	);
    
    -- controllo input
    if _mese < 1 or _mese > 12 then 
		signal sqlstate '45000'
        set message_text = 'Mese non valido!';
	end if;
    
    -- anno nel futuro o troppo vecchio
    if _anno > year(current_date) or (_anno < (year(current_date) - interval 1 year)) then
		signal sqlstate '45000'
        set message_text = "Dati non validi! Scegliere un mese ed anno complessivamente non più vecchi di 1 anno";
	end if;
    
    -- anno e mese complessivametne troppo vecchi
    if _anno <> year(current_date) then
		if _mese <> month(current_date - interval 1 month) then
			signal sqlstate '45000'
        set message_text = "Dati non validi! Scegliere un mese ed anno complessivamente non più vecchi di 1 anno";
		end if;
	end if;
    
    
    open interazioni;
    scan: loop
		fetch interazioni into fascia, utente, dispo, impost, inizio_int, fine_int, inizio_f, fine_f, consum;
		if finito = 1 then 
			leave scan;
        end if;
        
        -- TEST ONLY
		-- Essendo il db popolato semirandomicamente i consumi dei condizionatori sarebbero troppo complicati da "elaborare" 
        -- (sarebbe necessario ipotizzare anche un andamento della temperatura esterna per avere dei dati realistici)
        -- quindi per questioni di testing verranno azzerati
        if consum is null then
			set consum = 0;
		end if;
        
        
        # voglio identificare i record che stanno in una singola fascia oraria
        if ((hour(fine_int) < fine_f and day(inizio_int) = day(fine_int)) 
			or ((hour(inizio_int) = 23 or hour(inizio_int) < 7) and (hour(fine_int) = 23 or hour(fine_int) < 7))) then
        
			-- l'interazione inizia a finisce all'interno della stessa fascia oraria
			insert into div_fascia
				values 	(fascia, utente, dispo, impost, inizio_int, fine_int, consum);
		else
			/* 	
				altrimenti
				"spezzo" l'interazione in interazioni che stanno in una fascia oraria
            */
            if (hour(fine_int) = 23 or hour(fine_int) < 7) then
            -- facia a cavallo del cambio data
				set fascia_fine = 4;
            else
				set fascia_fine = 	(select fasciaoraria
									from	bilancio
									where	hour(fine_int) >= orainizio
											and hour(fine_int) < orafine);
			end if;
            
			-- inserisco la prima interazione
            insert into div_fascia
					values 	(fascia, utente, dispo, impost, inizio_int, timestamp(makedate(year(inizio_int), dayofyear(inizio_int))) + interval fine_f hour, consum);                    
			while fascia_fine <> fascia do
				-- passo alla fascia successiva
				set fascia = fascia + 1;
                if fascia > 4 then 
					set fascia = 1;
                end if;
                
                -- setto l'inizio della "nuova interazione"
                -- + trasformo in timestamp
                set inizio_int = timestamp(makedate(year(inizio_int), dayofyear(inizio_int))) + interval (select orainizio from 	bilancio where	fascia = fasciaoraria) hour;
                
                -- inserisco la "nuova interazione"
				if fascia_fine <> fascia then
					-- fine interazione corrisponde con la fine della fascia
                    insert into div_fascia
					values 	(fascia, utente, dispo, impost, inizio_int, timestamp(makedate(year(fine_int), dayofyear(fine_int))) + interval (select	orafine from bilancio where	fascia = fasciaoraria) hour, consum);
                else
					-- ultima interazione
                    insert into div_fascia
					values 	(fascia, utente, dispo, impost, inizio_int, fine_int, consum);
					
                end if;
            end while;
        end if;
    end loop scan;
    close interazioni;


    with consumo as (
		select	fasciaoraria, account, dispositivo, impostazione, orainizio, orafine, consumo as potenza, timestampdiff(second, orainizio, orafine)/3600 as tempo
        from	div_fascia
        where 	consumo <> 0		-- TEST ONLY non è necessario a regime
    )
    select	fasciaoraria, round(avg(tempo*potenza), 2) as 'consumo medio(Wh)'
    from 	consumo
    group 	by fasciaoraria
    ;
  
end $$
delimiter ;


-- call consumo_mese(10, 2021);

-- Operazione 6

/*
	Dato un dispositivo e un lasso di tempo torna 1 se il dispositivo è programmato per una partenza differita in quel periodo, 
    se è attualmente accesso senza una fine prestabilita o se è acceso e finisce all'interno delll'intervallo scelto.
*/

drop function if exists attivo;
delimiter $$
create function attivo(_dispositivo integer, _inizio timestamp, _fine timestamp)
returns boolean not deterministic
begin
    declare flag boolean default false;
    set flag = if((select 	dispositivo
				from	storico
                where	orainizio < _fine
						and orafine > _inizio
						and dispositivo = _dispositivo
				limit 1) > 0, 1, 0);
	return flag;
end $$
delimiter ;

-- Operazione 7
/*
	Classifica Temperatura colore delle luci più usata (come tempo) nella settiman precedente
*/
drop procedure if exists colore_luci;
delimiter $$
create procedure colore_luci()
begin
	declare settimana integer;
    declare inizio_s date;
    declare fine_s date;
    
    
    set settimana = week(current_Date)-1;
    
    set inizio_s = 
    (select	min(s.orainizio)
    from 	storico s
			inner join
            dispositivo d on d.codice = s.dispositivo
    where	week(s.orainizio) = settimana
            and d.tipologia = 0);
    
    set fine_s = 
    (select	max(s.orafine)
    from 	storico s
			inner join
            dispositivo d on d.codice = s.dispositivo
    where	week(s.orafine) = settimana
            and d.tipologia = 0);
    
    with intervalli as (
		select	ii.TemperaturaColore, 
				if(week(s.orainizio) <> settimana, timestamp(inizio_s), s.orainizio) as orainizio, 
				if(week(s.orafine) <> settimana, timestamp(fine_s) + interval 23 hour + interval 59 minute + interval 59 second, fine_s) as orafine
		from 	storico s
				inner join
				dispositivo d on d.codice = s.dispositivo
				inner join
				impostazioniilluminazione ii on ii.codice = s.impostazione
		where	(week(s.orainizio) = settimana
				or week(s.orafine) = settimana)
				and d.tipologia = 0
	), tempo as (
		select	temperaturacolore, sum(timestampdiff(second, orainizio, orafine)) as tempo
		from 	intervalli
        group by temperaturacolore
	)
    select	temperaturacolore,
			tempo/(sum(tempo)over(order by tempo rows between unbounded preceding and unbounded following))*100 as '%', 
            rank() over(order by tempo desc) as r
    from 	tempo
    order by r;
    
    
end $$
delimiter ;

-- call colore_luci;


-- Operazione 8
/*
	recupero impostazioni utilizzabili da un determinato dispositivo
*/
drop procedure if exists utilizzabili;
delimiter $$
create procedure utilizzabili(IN _dispositivo integer)
begin
	select	impostazione
    from 	utilizzabili 
    where	dispositivo = _dispositivo;
end $$
delimiter ;

-- call utilizzabili(7);



-- Operazione 9
/*
	implementa l'uso dell'operazione 2 per modificare l'inserimento del consumo (nello storico) per i dispositivi di condizionamento
*/
drop trigger if exists aggiorna_condizionatori;
delimiter $$
create trigger aggiorna_condizionatori
before insert on storico 
for each row
begin
	declare t_target double;
    declare t_esterna double;
    declare consumo double;
    declare dummy double;
    
    -- qua ci vorrebbe una chiamata per leggere il sensore di temperatura esterna
    set t_esterna = 15;
    
	if (select tipologia from dispositivo where new.dispositivo = codice) = 1 then
		set t_target = (select temperatura from impostazionicondizionamento where codice = new.impostazione)+15;
		call stima_condizionamento(new.dispositivo, t_esterna, t_target, new.orainizio, new.orafine, consumo, dummy);
        -- caso fortuito di temperatura esterna = temperatura target
        if consumo = 0 then
			set new.dispositivo = null;
		else
			set new.consumo = consumo;
		end if;
	end if;
end $$
delimiter ;


/*
	Procedura di utilità per lo spegnimento di un dispositivo interrompibile
    
    modifico il valore dell'attributo orafine che passa quindi da 'null' a 'current_timestamp'
*/

drop procedure if exists spegni_interrompibile;
delimiter $$
create procedure spegni_interrompibile(IN _dispositivo integer)
begin
	update storico 
	set orafine = current_timestamp()
		where	orainizio = (
							select 	*
							from 	(
									select 	max(s1.orainizio)
									from 	storico s1
									where	s1.dispositivo = 0
											and s1.OraInizio < current_timestamp()
									) as T
							);
end $$
delimiter ;


/*
	Gestione dei dati che si accumulano di continuo (storico, produzione, suggerimento)
	ogni mese cancello i dati più vecchi di 12 mesi -> nel database i dati delle relazione sopra citate restano in media 12.5 mesi
*/

drop event if exists cancellazione_parziale;
delimiter $$ 
create event cancellazione_parziale
on schedule every 1 month
do
begin
	delete from storico
	where	orariointerazione < current_timestamp - interval 12 month;

	delete from produzione
	where 	orario < current_timestamp - interval 12 month;

	delete from suggerimento
	where  orario < current_timestamp - interval 12 month;

end $$
delimiter ;