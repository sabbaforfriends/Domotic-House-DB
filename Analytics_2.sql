/*
	Parte 1: identifica consumo superiore alla produzione

	Parte 2: Consiglia cosa spegnere se c'è bisogno
*/


-- PARTE 1
-- dovrebbe essere un trigger
drop trigger if exists Controllo_energetico;
delimiter $$
create trigger Controllo_energetico
after insert on storico
for each row
begin
	
    declare produzione double;
    declare consumo_ double;
    
    -- recuperiamo la produzione "instantanea"
    -- set produzione = (select kW from produzione where orario = (select	max(orario) from produzione ))*1000;
    set produzione = (select kW from produzione where orario = (select	max(orario) from produzione where orario < current_timestamp()))*1000;
    -- calcolo il consumo attuale di tutti i dispositivi (compreso quello appena acceso)
    set consumo_ = (
					select	max(consumo)
					from 	storico
					where	OraInizio < current_timestamp()
							and (OraFine > current_timestamp()
							or Orafine is null));
	/*
    select produzione;
    select consumo_;*/
    if consumo_ > produzione then
		-- chiama consigli
        call consiglio_spegni();
        
	end if;
    
end $$
delimiter ;

-- PARTE 2
drop procedure if exists consiglio_spegni;
delimiter $$
create procedure consiglio_spegni()
begin
	-- tempo minimo di accensione per rientrare nella casistica di codice: 2
    declare min_tempo integer default 5;

	if (select count(*) from storico where orainizio < current_timestamp() and (orafine > current_timestamp or orafine is null)) = 1 then
		-- avvisi semplicemente l'utente che sta prelevando dalla rete elettrica
        select 'Il dispositivo appena acceso, da solo, supera la produzione attuale';
	end if;
    
    /*
    possiamo selezionare tutti i dispositivi attualmente accesi
	
    selezionare quelli che riteniamo che debbano essere spenti con un priorità maggiore
		caratteristiche che portano allo suggerire lo spegnimento
        0 - due o + dispositivi dello stesso tipo nella stessa stanza -> proporre di spegnere quello che consuma di più
        1 - due o + dispositivi accesi dalla stessa persona in stanze diverse
		2 - dispostivo acceso da più di tot ore (es 5 ore: possibile dimenticanza)
    */


    with accesi as (
		select 	*
        from 	storico
		where	orainizio < current_timestamp() 
				and (orafine > current_timestamp or orafine is null)
    ), escludi_non_interrompibili as (
		select	*
        from 	accesi
        where	impostazione not in (select codice from programma)
    ), stanza as (
		select	e.*, s.codicestanza as stanza, d.Tipologia, 
				count(*) over (partition by s.codicestanza, d.tipologia) as n
        from 	escludi_non_interrompibili e
				inner join
                dispositivo d on e.dispositivo = d.Codice
                inner join
                smartplug s on s.codice = d.CodicePresa
    ), stanza_fine as(
		select	*
        from 	stanza
        where	n > 1
    ), stessa_persona as (
		select	s1.*, s2.stanza as stanza2
        from 	stanza s1
				join
                stanza s2 on (s1.account = s2.account and s1.orariointerazione <> s2.orariointerazione)
		where	s1.stanza <> s2.stanza
    ), accesi_troppo as (
		select	*
        from 	escludi_non_interrompibili
        where	timestampdiff(minute, orainizio, current_timestamp)/60 > min_tempo
    )
    select	D.*, rank()over(order by consumo desc) as pos
    from 	
    (
    select	account, timestampdiff(minute, orainizio, current_timestamp) as tempo_accensione, dispositivo, impostazione, consumo, 2 as motivo
    from	accesi_troppo
    union
    select 	account, timestampdiff(minute, orainizio, current_timestamp) as tempo_accensione, dispositivo, impostazione, consumo, 1 as motivo
    from 	stessa_persona
    union
    select	account, timestampdiff(minute, orainizio, current_timestamp) as tempo_accensione, dispositivo, impostazione, consumo, 0 as motivo
    from 	stanza_fine
	) as D;
   
end $$
delimiter ;


