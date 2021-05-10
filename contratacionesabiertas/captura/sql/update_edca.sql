-- Actualización del rol al usuario del módulo dashboard
/*
1. Respaldar la base de datos
   pg_dump -U postgres edca > respaldo.sql
2. Respaldar la base de datos SIN PROPIETARIOS
   pg_dump -U postgres -O edca > respaldo_sin_owner.sql
3. Borrar la base de datos
   drop database edca;
4. Crear la base de datos edca
   create database edca;
5. otorgar permisos de los usuarios sobre la base
   grant all privileges on database edca to prueba_captura;
   grant all privileges on database edca to prueba_dashboard;
6. Importar la base de datos edca
   psql -U postgres edca < respaldo_sin_owner.sqsl
7. Ejecutar el script `owner_public.sql` para asignar el propietario al esquema public
   psql -U postgres edca < owner_public.sql
8. Ejecutar el script `owner_dashboard.sql` para asignar el propietario al esquema dashboard
   psql -U postgres edca < owner_dashboard.sql
9. En caso de que el esquema dashboard no tenga datos en su tabla items, correr el siguiente script:
   `insert into dashboard.item select * from public.item;`
10. En caso de que el esquema dashboard no tenga datos en su tabla budgetbreakdown, correr el siguiente script:
   insert into dashboard.budgetbreakdown select * from public.budgetbreakdown;
*/

-- Actualizacion de documentos utilizados para el envío a PNT
update DocumentType set title_esp = 'Convocatoria o invitación' where code = 'tenderNotice';
update documenttype set title_esp = 'Estudios de impacto urbano y ambiental' where code = 'environmentalImpact';
update public.documenttype set stage = '0' where code = 'contractText';

INSERT INTO DocumentType(id, stage, code, category, title, title_esp, description, source) VALUES
(47, 2,'openingOfProposals','basic','Opening Of Proposals','Documento en donde consta la presentación de las propuestas','Documento en donde consta la presentación de las propuestas',''),
(48, 5,'settlement','basic','Settlement','Finiquito','Documento elaborado una vez concluídos los trabajos derivados de un contrato celebrado con una dependencia o entidad del Estado. En este se hará constar los créditos a favor y en contra que resulten para cada una de las partes involucradas, tales son la dependecia y el contratista.',''),
(49, 4,'contractAmendment','basic','Contract Amendment','Convenio modificatorio','Documento en el que se detallan las modificaciones realizadas a las condiciones originales del contrato.',''),
(50, 5,'physicalReception','basic','Physical Reception','Acta de recepción de los trabajos ejecutados u homóloga en su caso','Documento elaborado por la entidad o dependecia en el que se procede a la recepción física  los trabajos realizados. Este documento se elabora dentro de los 15 días naturales siguientes a la debida terminación de los mismos, previa presentación de la garantía de defectos, vicios ocultos y de cualquier otra responsabilidad.',''),
(51, 2,'procurementMethodAuthorization','basic','Procurement Method Authorization','Autorización del ejercicio de la opción','Autorización escrita del titular de la dependencia o entidad, o de aquel servidor público en quién éste delegue dicha atribución para realizar la adjudicación directa.',''),
(52, 4,'suspensionNotice','basic','Suspension Notice','Comunicado de la suspensión','Documento  en el que las dependencias y entidades podrán suspender temporalmente, en todo o en parte, los trabajos contratados por cualquier causa justificada. Los titulares de las dependencias y los órganos de gobierno de las entidades designarán a los servidores públicos que podrán ordenar la suspensión y determinar, en su caso, la temporalidad de ésta, la que no podrá ser indefinida.',''),
(53, 5,'transferReport','advanced','Transfer Report','Reporte de transferencias','Documento de reporte de transferencias bancarias.','');

-- Creación de tabla Datos PNT
create table public.datapnt
(
	id integer NOT NULL,
	contractingprocess_id integer,
    fiscalYear integer,
    reportingPeriodStartDate timestamp without time zone,
    reportingPeriodEndDate timestamp without time zone,
	dataResponsibleunit text,
	valitationDate timestamp without time zone,
	updateDate timestamp without time zone,
    notes text,
    data_pnt boolean
);

CREATE SEQUENCE public.datapnt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

alter table public.datapnt owner to prueba_captura;
alter table public.datapnt_id_seq owner to prueba_captura;

ALTER SEQUENCE public.datapnt_id_seq OWNED BY public.datapnt.id;

ALTER TABLE ONLY public.datapnt ALTER COLUMN id SET DEFAULT nextval('public.datapnt_id_seq'::regclass);

SELECT pg_catalog.setval('public.datapnt_id_seq', 1, false);

ALTER TABLE ONLY public.datapnt
    ADD CONSTRAINT datapnt_pkey PRIMARY KEY (id);

--
-- Data for Name: datapnt; Type: TABLE DATA; Schema: public; Owner: user_back
--

COPY public.datapnt (id, contractingprocess_id, fiscalyear, reportingperiodstartdate, reportingperiodenddate, dataresponsibleunit, valitationdate, updatedate, notes) FROM stdin;
\.

--
-- Name: datapnt datapnt_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_back
--

ALTER TABLE ONLY public.datapnt
    ADD CONSTRAINT datapnt_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;

-- scripts para ejecutar en ambos esquemas
alter table public.budgetbreakdown add column origin varchar;
alter table public.budgetbreakdown add column fund_type varchar;

alter table dashboard.budgetbreakdown add column fund_type varchar;
alter table dashboard.budgetbreakdown add column origin varchar;

ALTER TABLE roles RENAME COLUMN clarificationmeetingattendee TO attendee;
ALTER TABLE roles RENAME COLUMN clarificationmeetingofficial TO official;
alter table roles add column responsibleunit boolean;
alter table roles add column requestingunit boolean;
alter table roles add column contractingunit boolean;
alter table roles add column technicalunit boolean;

update implementationtransactions set payment_method = 'wireTransfe' where payment_method = 'wireTransfer';

alter table guarantees rename column guaranteetype to type;
alter table guarantees rename column guaranteedobligations to obligations;

update guarantees set type = 'letterOfCredit' where type = 'creditLetter';

update relatedprocedure set relationship_type = 'planning' where relationship_type = 'planningProcess';
update relatedprocedure set relationship_type = 'parent' where relationship_type = 'mainContract';
update relatedprocedure set relationship_type = 'prior' where relationship_type = 'previousProcess';

update tender set procurementmethod_rationale_id = 'Artículo 26 fracción I RAAS' where procurementmethod_rationale_id = 'Artículo 26 I RAAS';
update tender set procurementmethod_rationale_id = 'Artículo 41 fracción VII RAAS AD' where procurementmethod_rationale_id = 'Artículo 41 VII RAAS AD';
update tender set procurementmethod_rationale_id = 'Artículo 41 fracción VIII RAAS AD' where procurementmethod_rationale_id = 'Artículo 41 VIII RAAS AD';
update tender set procurementmethod_rationale_id = 'Artículo 41 fracción X RAAS AD' where procurementmethod_rationale_id = 'Artículo 41 X RAAS AD';
update tender set procurementmethod_rationale_id = 'Artículo 41 fracción XI RAAS AD' where procurementmethod_rationale_id = 'Artículo 41 XI RAAS AD';
update tender set procurementmethod_rationale_id = 'Artículo 41 fracción XII RAAS AD' where procurementmethod_rationale_id = 'Artículo 41 XII RAAS AD';

-- Update 21-abril-21
alter table public.planning add column numberofbeneficiaries numeric;

alter table dashboard.planning add column numberofbeneficiaries numeric;

-- Ejecutar para actualizar roles con datos en el esquema dashboard
truncate table roles restart identity;

insert into dashboard.roles select 
    a.contractingprocess_id,
    a.parties_id,
    a.id,
    a.buyer,
    a.procuringentity,
    a.supplier,
    a.tenderer,
    a.funder,
    a.enquirer,
    a.payer,
    a.payee,
    a.reviewbody,
    a.attendee,
    a.official,
    a.invitedsupplier,
    a.issuingsupplier,
    a.guarantor,
    a.requestingunit,
    a.contractingunit,
    a.technicalunit,
    a.responsibleunit
from public.roles as a
join public.contractingprocess as b on a.contractingprocess_id = b.id
where b.published = true
order by a.id;

-- Ejecutar para crear tablas de project
/*
sequelize db:migrate
sequelize db:seed:all 
*/

-- Ejecutar para eliminar project

/*
sequelize db:migrate:undo:all
*/
