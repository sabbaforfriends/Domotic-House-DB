
/*
	Analisi di quanto spesso capita che utenti differenti abbiano, nello stesso momento un dispositivo attivo da loro acceso in precedenza
	utilità: studiare quanto spesso se utente A accende un dispositivo allora lo accende anche utente B e/o utente C, etc
			 potrebbe essere utile capire quali utenti sono più spesso contemporaneamente a casa
*/

drop procedure if exists analytics;
delimiter $$
create procedure analytics(IN _supporto_min double, IN _confidenza_min double, in _inizio_intervallo date, IN _fine_intervallo date)
begin


	declare inizio timestamp;
    declare fine timestamp;


	-- controllo input
	if (_inizio_intervallo > current_date or _fine_intervallo > current_date) then
		signal sqlstate '45000'
		set message_text = 'Inserire date valide!';
	end if;

	set inizio = timestamp(_inizio_intervallo);
    set fine = timestamp(_fine_intervallo);

	drop table if exists test;
	CREATE TABLE test (
		orario TIMESTAMP,
		utente VARCHAR(30) DEFAULT 'nessuno',
		PRIMARY KEY (orario , utente)
	);
    
	
    -- orari
    -- creo artificalmente dei timestamp in cui compare la data e solo la parte delle ore (minuti e secondi ci sono ma sono 00:00)
    while inizio < fine do
		Insert into test (orario)
		select inizio;
            
		set inizio = inizio + interval 1 hour;
    end while;
    

    Replace into test
    select 	orario, account
    from 	test
			join
            storico
	where	orario > orainizio
			and orario < orafine;

/*
	-- test itemset
    Replace into test
		Values 	(timestamp(current_date), 'A'),
				(timestamp(current_date), 'B'),
                (timestamp(current_date), 'C'),
                (timestamp(current_date + interval 1 day), 'A'),
                (timestamp(current_date + interval 1 day), 'C'),
                (timestamp(current_date + interval 1 day), 'B'),
                (timestamp(current_date + interval 1 day), 'D'),
                (timestamp(current_date + interval 2 day), 'A'),
                (timestamp(current_date + interval 2 day), 'C'),
                (timestamp(current_date + interval 3 day), 'D'),
                (timestamp(current_date + interval 4 day), 'C'),
                (timestamp(current_date + interval 4 day), 'A'),
                (timestamp(current_date + interval 5 day), 'D'),
                (timestamp(current_date + interval 5 day), 'B'),
                (timestamp(current_date + interval 5 day), 'C'),
                (timestamp(current_date + interval 6 day), 'A'),
                (timestamp(current_date + interval 6 day), 'B'),
                (timestamp(current_date + interval 7 day), 'C'),
                (timestamp(current_date + interval 7 day), 'D'),
                (timestamp(current_date + interval 7 day), 'B'),
                (timestamp(current_date + interval 8 day), 'B'),
                (timestamp(current_date + interval 9 day), 'B');
   
	-- visualizzazione pivot del test itemset
    select	orario, 
			if(count(if(utente = 'A', 1, null))>0, 1, 0) as A,
            if(count(if(utente = 'B', 1, null))>0, 1, 0) as B,
            if(count(if(utente = 'C', 1, null))>0, 1, 0) as C,
            if(count(if(utente = 'D', 1, null))>0, 1, 0) as D
		from 	test
		where 	utente <> 'nessuno'
	group by orario;
*/

	-- visualizzazione pivot del dataset
	select	orario, 
			if(count(if(utente = 'GiovanniRusso', 1, null))>0, 1, 0) as 'GiovanniRusso',
            if(count(if(utente = 'LuciaFerrari', 1, null))>0, 1, 0) as 'LuciaFerrari',
            if(count(if(utente = 'MarioRusso', 1, null))>0, 1, 0) as 'MarioRusso',
            if(count(if(utente = 'MartaRusso', 1, null))>0, 1, 0) as 'MartaRusso'
		from 	test
		where 	utente <> 'nessuno'
	group by orario;

	-- eliminazione dei record in cui nessun utente ha un dispositivo acceso
    delete from test
    where	utente = 'nessuno';
    
    with test_1 as (
		-- squash su orario
		select	orario
        from 	test
        group by orario
    ), totale as (
		select count(*)
        from 	test_1
    ), large as (
		-- troviamo il supporto di ogni singolo utente 
		select	utente as A, count(*)/(select * from totale) as supporto
		from	test
		group by utente
	), step1 as (
		-- teniamo solo gli utenti che, singolarmente, hanno un supporto maggiore del minimo
		select	A
		from	large
		where	supporto > _supporto_min
	), coppie as (
		-- tra gli utenti selezionati, cerco tutte le possibili coppie
		select	A.A as A, B.A as B
		from	step1 A 
				join
				step1 B
	), conf2 as (
		-- calcoliamo supporto e confidenza di ogni coppia
		select	A.utente as A, B.utente as B,
				(count(*)/(select * from totale)) as supporto,
				((count(*)/(select * from totale)) / ((select supporto from large where A = A.utente))) as `confidenzaA>B`
		from 	test A
				inner join
				test B using(orario)
		where	A.utente in (select A from step1)
				and B.utente in (select A from step1)
				and A.utente <> B.utente
		group by A.utente, B.utente
    ), step2 as (
		-- tengo solo le coppie con supporto e confidenza superiori al minimo
		select	*
        from 	conf2
        where	supporto > _supporto_min
	), triple as (
		-- costrusco le triplette a partire dalle coppie, aggiungengo il componente mancante
		select	T1.A as A, T1.B as B, T2.A as C
        from 	step2 T1
				join
                step1 T2
		where	T1.A <> T2.A
				and T1.B <> T2.A
                and
                -- mi assicuro che le coppie (sottoinsiemi) siano frequenti
				((T1.A, T2.A) in (select A, B from step2)
				and (T1.B, T2.A) in (select A, B from step2))
    ), pre_conf3 as (
		-- preparazione ai calcoli
		select	A.utente as A, B.utente AS B, C.utente as C,
				(count(*)/(select * from totale)) as supporto,
                count(*) as tot
		from 	test A
				inner join
				test B using(orario)
				inner join
				test C using(orario)
				inner join
				triple t on (t.A = A.utente and t.B = B.utente and t.C = C.utente)
		group by A.utente, B.utente, C.utente
    ), conf3 as (
		-- supporto della regola e confidenze delle varie possiblità
		select	A, B, C, supporto,
				((C.tot/(select * from totale))/(select supporto from conf2 T where T.A = C.A and T.B = C.B)) as `confidenzaAB>C`,
                ((C.tot/(select * from totale))/(select supporto from large where A = C.A)) as `confidenzaA>BC`
        from 	pre_conf3 C
    ), step3 as (
		-- tengo solo le regola che superano il supporto minimo
		select	*
        from 	conf3
        where 	supporto > _supporto_min
    ), quattro as (
		-- formo le possibili combinationi di 4 elementi, i sui sotto elementi (sia singolarmente che in coppie e triple) sono tutti frequenti
		select	T1.A as A, T1.B as B, T1.C as C, T2.A as D
        from 	step3 T1
				join
                step1 T2
		where	T1.A <> T2.A
				and T1.B <> T2.A
                and T1.C <> T2.A
                and (
					-- controllo che le coppie siano frequenti
                    ((T1.A, T2.A) in (select A, B from step2))
                    and ((T1.B, T2.A) in (select A, B from step2))
                    and ((T1.C, T2.A) in (select A, B from step2))
                    -- controllo che le triplette siano frequenti
                    and ((T1.A, T1.B, T2.A) in (select A, B, C from step3))
                    and ((T1.A, T1.C, T2.A) in (select A, B, C from step3))
                    and ((T1.B, T1.C, T2.A) in (select A, B, C from step3))
                )
    ), pre_conf4 as (
		-- preparazione calcoli
		select	A.utente as A, B.utente AS B, C.utente as C, D.utente as D,
				(count(*)/(select * from totale)) as supporto,
                count(*) as tot
		from 	test A
				inner join
				test B using(orario)
				inner join
				test C using(orario)
                inner join 
                test D using(orario)
				inner join
                quattro q on (q.A = A.utente and q.B = B.utente and q.C = C.utente and q.D = D.utente)
		group by A.utente, B.utente, C.utente	
    ), conf4 as (
		-- supporto delle regola e possibili confidenze
		select	A, B, C, D, supporto,
				((C.tot/(select * from totale))/(select supporto from conf3 T where T.A = C.A and T.B = C.B and T.C = C.C)) as `confidenzaABC>D`,
                ((C.tot/(select * from totale))/(select supporto from conf2 T where T.A = C.A and T.B = C.B)) as `confidenzaAB>CD`,
                ((C.tot/(select * from totale))/(select supporto from large where A = C.A)) as `confidenzaA>BCD`
        from 	pre_conf4 C
    ), step4 as (
		-- tengo solo quello le regole con supporto superiore al minimo
		select	*
        from 	conf4
        where 	supporto > _supporto_min 
    )
    -- visualizzazione finale
    -- NULL "delimita" le regole con meno di 4 utenti perchè devo poter visualizzare fino a 4 utenti
    -- Nella parte della confidenza, quando il numero di utenti è inferiore a 4, questa è da intendersi esclusivamente sugli utenti non NULL
	select	A, B, C, D, supporto, `confidenzaA>BCD`, `confidenzaAB>CD`, `confidenzaABC>D`
    from 	step4
    where	`confidenzaA>BCD` > _confidenza_min
			or `confidenzaAB>CD` > _confidenza_min
            or `confidenzaABC>D` > _confidenza_min
		union
    select	A, B, C, null, supporto, `confidenzaA>BC`, `confidenzaAB>C`, null
    from 	step3
    where	`confidenzaA>BC` > _confidenza_min
			or `confidenzaAB>C` > _confidenza_min
		union
    select	A, B, null, null, supporto, `confidenzaA>B`, null, null
    from 	step2
	where	`confidenzaA>B` > _confidenza_min
		union
    select	A, null, null, null, supporto, null, null, null
    from 	large;
end 
$$
delimiter ;

-- esempio analisi ultimi 15 giorni
-- con supporto minimo 70%  e confidenza minima 70%
call analytics(0.7, 0.7, current_date() - interval 15 day, current_date());





