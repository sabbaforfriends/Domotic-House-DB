
# UNIVERSITÀ DI PISA

**DOCUMENTAZIONE PROGETTO BASI DI DATI**

**Autori:**
Pietro Čok
Lorenzo Salvatelli

**Anno accademico:**
2020/2021

---

## Sommario

- [Glossario](#glossario)
- [Descrizione Diagramma E-R](#descrizione-diagramma-e-r)
    - [Area dispositivo](#area-dispositivo)
    - [Area Utente](#area-utente)
    - [Area Planimetria](#area-planimetria)
    - [Area Energia](#area-energia)
- [Ristrutturazione](#ristrutturazione)
- [Operazioni sui dati](#operazioni-sui-dati)
    - [Tavola Volumi](#tavola-volumi)
    - [Operazione 1](#operazione-1)
    - [Operazione 2](#operazione-2)
    - [Operazione 3](#operazione-3)
    - [Operazione 4](#operazione-4)
    - [Operazione 5](#operazione-5)
    - [Operazione 6](#operazione-6)
    - [Operazione 7](#operazione-7)
    - [Operazione 8](#operazione-8)
- [Triggers](#triggers)
- [Modello Logico](#modello-logico)
    - [Analisi dipendenze funzionali](#analisi-dipendenze-funzionali)
    - [Vincoli](#vincoli)
- [Creazione e popolamento del database](#creazione-e-popolamento-del-database)
- [Data Analytics](#data-analytics)
    - [Analytics 1](#analytics-1)
    - [Analytics 2](#analytics-2)

---

## Glossario

### Area Dispositivi

| Termine | Descrizione | Sinonimi | Collegamenti |
| :--- | :--- | :--- | :--- |
| **Dispositivo** | oggetto elettronico che svolge delle funzioni | | smart-plug, ricorrenza, predefinite, storico, impostazioni, suggerimento |
| **Smart-plug** | Interfaccia dispositivo-database | | dispositivo, stanza |
| **Specifiche** | Particolari caratteristiche di un dispositivo | | dispositivo |
| **Ricorrenza** | Contiene informazioni sulle ricorrenze: dispositivo, impostazione, data inizio/fine, giorno e orari di attivazione | | Anno (attributo), dispositivo, impostazioni |
| **Anno** | Booleano: se vero considera anche la parte 'anno' delle date inizio/fine | | ricorrenza |
| **Utilizzabili** | coppie dispositivo-impostazioni valide | | dispositivo, impostazione |
| **Storico Interazioni** | contiene tutte le informazioni delle interazioni tra utenti e dispositivi | Storico, Interazioni | utente, impostazione, dispositivo, bilancio |
| **Impostazione** | particolare settaggio delle caratteristiche di un dispositivo | impostazioni | impostazioni specifiche |
| **Impostazioni Illuminazione** | impostazioni dei dispositivi di illuminazione | impostazioni specifiche | impostazioni |
| **Impostazioni Condizionamento** | impostazioni dei dispositivi di condizionamento | impostazioni specifiche | impostazioni |
| **Programma** | impostazioni dei dispositivi non interrompibili | impostazioni specifiche | impostazioni |
| **Altre impostazioni** | impostazioni di altri dispositivi di cui non si è "attualmente" tenuto conto | impostazioni specifiche | impostazioni |
| **Suggerimento** | tiene salvati i suggerimenti proposti dal sistema e se accettati | | dispositivo, impostazione, utente |
| **Predefinite** | raccolta di impostazioni in gruppi per accensione simultanea | | impostazione, dispositivo |

### Area Utente

| Termine | Descrizione | Sinonimi | Collegamenti |
| :--- | :--- | :--- | :--- |
| **Account** | profilo collegato ad un utente per interagire col DB | | utente, storico, suggerimento |
| **Utente** | persona fisica | persona | account, documento, contratto |
| **Documento** | identificatore di una singola persona | | utente |
| **Contratto** | contenitore per il livello di dispersione | | livello dispersione, utente |

### Area Planimetria

| Termine | Descrizione | Sinonimi | Collegamenti |
| :--- | :--- | :--- | :--- |
| **Stanza** | area interna della casa | | apertura, smart-plug |
| **Apertura** | collegamento tra stanze o con l'esterno | porta, finestra, portafinestra | Stanza, tipo |
| **Tipo** | Tipologia dell'apertura (include caratteristica 'accesso') | | apertura |

### Area Energia

| Termine | Descrizione | Sinonimi | Collegamenti |
| :--- | :--- | :--- | :--- |
| **Bilancio energetico** | indica gli intervalli di ogni fascia oraria | | pannelli, storico |
| **Pannelli** | Fonte di energia rinnovabile | pannelli fotovoltaici | bilancio energetico |

---

## Descrizione Diagramma E-R

### Area dispositivo

**Dispositivo:**
Entità che rappresenta un dispositivo (tabella con codice unico, nome e tipologia). Valori tipologia:
- ‘0’ - illuminazione
- ‘1’ - condizionamento
- ‘2’ - non interrompibile (programmi)
- ‘3’ - altri

**Storico interazioni:**
Interazione utente-dispositivo. Identificata da dispositivo e ora di accensione. Include 'Orario interazione', 'Ora Inizio' e 'Ora Fine' (inizialmente null).

**Smart-Plug:**
Interfaccia per rendere "intelligente" il dispositivo. Ha un codice e uno stato "attiva".

**Specifiche:**
Caratteristiche particolari (es. efficienza condizionatori).

**Predefinite:**
Insieme di coppie dispositivo-impostazione per accensione simultanea.

**Ricorrenza:**
Interazione pianificata (giorno settimana, ora inizio/fine, sequenza settimane). L'attributo 'anno' (TRUE/FALSE) determina se è limitata a un periodo o "sempre".

**Impostazione:**
Combinazioni di regolazioni. L'attributo 'consumo' indica la potenza richiesta (null per i condizionatori, calcolato dinamicamente).

**Programma:**
Programmi per dispositivi non interrompibili, caratterizzati dalla durata.

### Area Utente

**Contratto:** Contiene il livello di dispersione della casa.
**Utente:** Persona fisica (Codice Fiscale, nome, cognome, nascita, telefono).
**Documento:** Dati dei documenti degli utenti.
**Account:** Interfaccia utente-database (nome account, password, domanda/risposta sicurezza).

### Area Planimetria

**Stanza:** Identificata da codice, nome, dimensioni e piano.
**Apertura:** Porte, finestre, portafinestre.
**Accesso:** Relazione Stanza-Apertura. Gestisce l'orientamento (N, S, E, W, ecc.).
**Tipo:** Suddivide le aperture e indica se sono punti di accesso (TRUE/FALSE).

### Area Energia

**Bilancio energetico:** Fasce orarie del contratto elettrico (numero, ora inizio/fine).
**Pannelli:** Produzione energia rinnovabile salvata ogni 10 minuti (timestamp e kW).

---

## Ristrutturazione

Il diagramma ER prevede una sola generalizzazione sulle impostazioni. Si è mantenuta sia l’entità genitore che le figlie per evitare troppe associazioni singole e permettere l'accesso diretto all'attributo 'consumo'. Non sono presenti attributi multivalore o ridondanze (inizialmente).

---

## Operazioni sui dati

### Tavola Volumi

| Area | Tabella | Volume |
| :--- | :--- | :--- |
| **UTENTE** | Contratto | 1 |
| | Utente | 4 |
| | Verifica | 4 |
| | Documento | 4 |
| | Iscrizione | 4 |
| | Account | 4 |
| **PLANIMETRIA** | Apertura | 25 |
| | Accesso | 33 |
| | Stanza | 11 |
| | Tipo | 3 |
| **ENERGIA** | Produzione | 54000 |
| | Bilancio | 4 |
| **DISPOSITIVI** | SmartPlug | 43 |
| | Dispositivo | 43 |
| | ImpostazioniIlluminazione | 50 |
| | ImpostazioniCondizionamento | 200 |
| | Programma | 22 |
| | Altre impostazioni | 0 |
| | Impostazioni | 272 |
| | Utilizzabili | 3472 |
| | Storico | 45000 |
| | Suggerimento | 22500 |
| | Predefinite | 0 |
| | Ricorrenza | 0 |
| | Specifiche | 2 |
| | Possiede | 20 |

**Ipotesi:** 4 utenti, 120 interazioni/giorno, dati mantenuti per 12,5 mesi. Produzione salvata ogni 10 min.

---

### Operazione 1
**Descrizione:** Generazione suggerimenti basati su energia rinnovabile.
**Input:** Nessuno.
**Output:** Dispositivo, Programma.

| Entità/Relazione | Accessi | Tipo | Motivo |
| :--- | :--- | :--- | :--- |
| Produzione | 1 | L | Check inizio operazione |
| Produzione | 72 | L | Stima produzione |
| Storico | 90 | L | Dispositivi accesi |
| Impostazione | 90 | L | Consumo dispositivi accesi |
| Programma | 22 | L | Recupero durata programma |
| Impostazione | 22 | L | Recupero consumo |
| Suggerimento | 1 | S | Salvataggio suggerimento |

**Algoritmo:** Eseguito ogni 10 min tramite *event*. Stima la produzione delle successive 3 ore (media delle 4 settimane precedenti) e suggerisce il programma a consumo maggiore compatibile con l'energia disponibile. Introdotta ridondanza 'consumo' nello storico per ottimizzare.

---

### Operazione 2
**Descrizione:** Stima consumi condizionamento per un dato giorno.
**Input:** Dispositivo, Temp Esterna, Temp Target, Accensione, Spegnimento.
**Output:** Potenza media richiesta, Produzione media.

| Entità | Accessi | Tipo | Descrizione |
| :--- | :--- | :--- | :--- |
| Contratto | 1 | L | Livello dispersione |
| Possiede | 1 | L | Collegamento specifiche |
| Specifiche | 1 | L | Valori specifiche condizionatori |
| Dispositivo | 1 | L | Codice smartPlug |
| Smartplug | 1 | L | Codice stanza |
| Stanza | 1 | L | Dimensioni stanza |

**Formula potenza termica:** $P_t = CD * (T_{est} - T_{target}) * A$
*(CD: coeff. dispersione, A: superficie esterna ipotizzata come metà della laterale).*

---

### Operazione 3
**Descrizione:** Classifica quotidiana dispositivi più utilizzati.
**Input:** Nessuno. **Output:** Lista dispositivi.
**Algoritmo:** Group by su dispositivo nello storico del giorno corrente. Valutata e scartata ridondanza 'tempo di utilizzo' per eccessive scritture.

### Operazione 4
**Descrizione:** Nome dell'ultimo utente che ha interagito con un dispositivo.
**Input:** Dispositivo. **Output:** Nome utente.
**Nota:** Introdotta ridondanza 'ultimo utilizzatore' su Dispositivo per evitare 45.000 accessi allo storico.

### Operazione 5
**Descrizione:** Consumo medio per fascia oraria in un mese dato.
**Input:** Mese, Anno. **Output:** Lista fasce e consumo medio.
**Algoritmo:** Suddivisione delle interazioni che a cavallo di più fasce orarie tramite cursore.

### Operazione 6
**Descrizione:** Verifica se un dispositivo è occupato in un lasso di tempo.
**Input:** Dispositivo, Inizio, Fine. **Output:** Boolean.

### Operazione 7
**Descrizione:** Classifica temperatura colore luci più usata nella settimana precedente.
**Input:** Nessuno. **Output:** Classifica (codice colore, %).

### Operazione 8
**Descrizione:** Mostra tutte le impostazioni utilizzabili da un dispositivo.
**Input:** Dispositivo. **Output:** Lista impostazioni.

---

## Triggers

- **Blocca_attivi:** Impedisce inserimento nello storico se il dispositivo è già acceso.
- **Aggiorna_storico:** Aggiorna ridondanza consumo e fascia oraria nello storico.
- **Aggiorna_condizionatori:** Calcola e aggiorna il consumo specifico dei condizionatori.
- **Fascia_produzione:** Associa la fascia oraria ad ogni record di produzione.
- **Attiva_suggerimento:** Inserisce l'interazione quando un suggerimento viene accettato.

---

## Modello Logico

- **SmartPlug**(_Codice_, Attiva, CodiceStanza)
- **Dispositivo**(_Codice_, Nome, UltimoUtilizzatore, CodicePresa, Tipologia)
- **Specifiche**(_Nome_, Valore)
- **Possiede**(_Dispositivo_, _Specifica_)
- **Impostazioni**(_Codice_, Consumo)
- **ImpostazioniIlluminazione**(_Codice_, Intensità, TemperaturaColore)
- **ImpostazioniCondizionamento**(_Codice_, Temperatura, Umidità)
- **Programma**(_Codice_, Durata)
- **AltreImpostazioni**(_Codice_, Potenza)
- **Utilizzabili**(_Dispositivo_, _Impostazione_)
- **Storico**(_Account_, _OrarioInterazione_, Dispositivo, Impostazione, Orainizio, Orafine, Consumo, FasciaOraria)
- **Suggerimento**(_Codice_, Dispositivo, Impostazione, Orario, Scelto, Account)
- **Predefinita**(_Codice_, _Dispositivo_, Impostazione)
- **Ricorrenza**(_Dispositivo_, _Impostazione_, _Giorno_, _DataInizio_, DataFine, Anno, Orainizio, Orafine)
- **Utente**(_CodiceFiscale_, Nome, Cognome, Telefono, DataNascita)
- **Contratto**(_LivelloDispersione_, Intestatario)
- **Account**(_NomeAccount_, Password, DomandaSicurezza, RispostaSicurezza)
- **Iscrizione**(_NomeAccount_, _CodiceFiscale_, DataIscrizione)
- **Documento**(_Numero_, Tipologia, EnteRilascio, Scadenza)
- **Verifica**(_NumeroDocumento_, _Utente_)
- **Tipo**(_Tipologia_, Accesso)
- **Apertura**(_Codice_, Tipologia)
- **Stanza**(_Codice_, Nome, Piano, Altezza, Larghezza, Lunghezza)
- **Accesso**(_CodiceApertura_, _CodiceStanza_, Orientamento)
- **Bilancio**(_FasciaOraria_, OraInizio, OraFine)
- **Produzione**(_Orario_, kW, FasciaOraria)

Tutte le tabelle sono in **BCNF**.

---

## Vincoli di Integrità (Esempi)
- `Apertura.Tipologia -> Tipo.Tipologia`
- `Accesso.CodiceApertura -> Apertura.Codice`
- `Contratto.Intestatario -> Utente.CodiceFiscale`
- `Dispositivo.Tipologia: >= 0 AND <= 3`
- `Ricorrenza.Giorno: > 0 AND <= 7`

---

## Creazione e popolamento
File principali: `Creazione Database.sql`, `Operazioni.sql`, `Triggers.sql`, `PopolamentoDatabaseFinale.sql`.
Per tabelle grandi (Storico, Produzione) usato approccio automatizzato (script C++ `Solargen.cpp` per dati fotovoltaici verosimili su curva gaussiana).

---

## Data Analytics

### Analytics 1: Regole di Associazione (Apriori)
Ricerca di regole di implicazione forte per capire quando utenti diversi usano dispositivi contemporaneamente.
**Input:** Minimo supporto, minima confidenza, intervallo temporale.
**Procedura:** Generazione large-itemset basati su (ora, account) e applicazione algoritmo Apriori.

### Analytics 2: Gestione Sprechi Energetici
Analisi in tempo reale se il consumo supera la produzione fotovoltaica. Un trigger avvia l'analisi dei dispositivi meno utili basandosi su:
1. Più dispositivi stessa tipologia in stessa stanza.
2. Dispositivi accesi dalla stessa persona in stanze diverse.
3. Dispositivi accesi da troppo tempo (dimenticanze).
Viene presentato all'utente un elenco ordinato per consumo di dispositivi "consigliati" da spegnere.