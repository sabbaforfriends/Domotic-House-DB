-- impedisce l'inserzione se il dispositivo è già in uso
-- o se è già stato scelto da un utente qualsiasi per un'attivazione differita

DROP trigger IF EXISTS blocca_attivi;
delimiter $$

CREATE trigger blocca_attivi
BEFORE INSERT ON storico
FOR EACH ROW
BEGIN
  
  declare tmp boolean default 0;
  
  set tmp = (
  select  count(*)
  from    storico s
  where   new.dispositivo = s.dispositivo
          and (new.OraInizio <= s.Orafine
               and new.orafine >= s.orainizio)
  );
  
  if (tmp > 0) then
	/*
	-- usato durante il popolamento per questioni di comodità
    -- praticamente vogliamo far fallire il singolo inserimento che da problemi ma continuare con gli altri
    -- settiamo a null un attributo che non può essere null e usiamo un insert IGNORE che impedisce l'inserimento dei record che danno errore ma non arresta l'esecuzione
    set new.dispositivo = null;
    */
	
	signal sqlstate '45000'
	set message_text = 'Dispositivo già attivo o impostato per un intervallo non valido!';
  end if;

END $$
delimiter ;


-- aggiunge la ridondanza consumo ad ogni record
drop trigger if exists aggiorna_storico;
delimiter $$
create trigger aggiorna_storico
before insert on storico
for each row 
begin

	-- aggiorna ridondanza 'consumo
	set new.consumo = (select consumo from impostazioni where new.impostazione = codice);
    
    
    -- inserisce la fascia oraria corrispondere all'inzio dell'impostazione
    if (hour(new.orainizio) >= 23 or hour(new.orainizio) < 7) then
		set new.fasciaoraria = 4;
	else
		set new.fasciaoraria = (select b.fasciaoraria 
								from bilancio b
                                where b.orainizio = (select max(b1.orainizio) 
													from bilancio b1 
                                                    where b1.orainizio <= hour(new.orainizio)) 
									and b.orafine = (select min(b2.orafine) 
													from bilancio b2 
                                                    where b2.orafine > hour(new.orainizio)));
	end if;
end $$
delimiter ;


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





-- affianca ad ogni orario la fascia oraria in cui si colloca
drop trigger if exists fascia_produzione;
delimiter $$
create trigger fascia_produzione
before insert on produzione
for each row
begin

    if (hour(new.orario) >= 23 or hour(new.orario) < 7) then
		set new.fasciaoraria = 4;
	else
		set new.fasciaoraria = (select b.fasciaoraria 
								from bilancio b
                                where b.orainizio = (select max(b1.orainizio) 
													from bilancio b1 
                                                    where b1.orainizio <= hour(new.orario)) 
									and b.orafine = (select min(b2.orafine) 
													from bilancio b2 
                                                    where b2.orafine > hour(new.orario)));
	end if;
end $$
delimiter ;



-- attiva un suggerimento
drop trigger if exists attiva_suggerimento;
delimiter $$
create trigger attiva_suggerimento
after update on suggerimento
for each row
begin
	if new.scelto = 1 then
		if current_timestamp() < new.orario + interval 10 minute then
			insert into storico 
				values (new.account, current_timestamp(), new.dispositivo, new.impostazione, current_timestamp(), current_timestamp() + interval (select durata from programma where codice = new.impostazione) minute);
		end if;
    end if;
end $$
delimiter ;

