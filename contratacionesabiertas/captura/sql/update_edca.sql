-- Actualizacion de documentos utilizados para el envío a PNT
update DocumentType set title_esp = 'Convocatoria o invitación' where code = 'tenderNotice';
update documenttype set title_esp = 'Estudios de impacto urbano y ambiental' where code = 'environmentalImpact';

INSERT INTO DocumentType(id, stage, code, category, title, title_esp, description, source) VALUES
(47, 2,'openingOfProposals','basic','Opening Of Proposals','Documento en donde consta la presentación de las propuestas','Documento en donde consta la presentación de las propuestas',''),
(48, 5,'settlement','basic','Settlement','Finiquito','Documento elaborado una vez concluídos los trabajos derivados de un contrato celebrado con una dependencia o entidad del Estado. En este se hará constar los créditos a favor y en contra que resulten para cada una de las partes involucradas, tales son la dependecia y el contratista.',''),
(49, 4,'contractAmendment','basic','Contract Amendment','Convenio modificatorio','Documento en el que se detallan las modificaciones realizadas a las condiciones originales del contrato.',''),
(50, 5,'physicalReception','basic','Physical Reception','Acta de recepción de los trabajos ejecutados u homóloga en su caso','Documento elaborado por la entidad o dependecia en el que se procede a la recepción física  los trabajos realizados. Este documento se elabora dentro de los 15 días naturales siguientes a la debida terminación de los mismos, previa presentación de la garantía de defectos, vicios ocultos y de cualquier otra responsabilidad.',''),
(51, 2,'procurementMethodAuthorization','basic','Procurement Method Authorization','Autorización del ejercicio de la opción','Autorización escrita del titular de la dependencia o entidad, o de aquel servidor público en quién éste delegue dicha atribución para realizar la adjudicación directa.',''),
(52, 4,'suspensionNotice','basic','Suspension Notice','Comunicado de la suspensión','Documento  en el que las dependencias y entidades podrán suspender temporalmente, en todo o en parte, los trabajos contratados por cualquier causa justificada. Los titulares de las dependencias y los órganos de gobierno de las entidades designarán a los servidores públicos que podrán ordenar la suspensión y determinar, en su caso, la temporalidad de ésta, la que no podrá ser indefinida.','');


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
alter table budgetbreakdown add column origin varchar;
alter table budgetbreakdown add column fund_type varchar;

ALTER TABLE roles RENAME COLUMN clarificationmeetingattendee TO attendee;
ALTER TABLE roles RENAME COLUMN clarificationmeetingofficial TO official;
alter table roles add column responsibleunit boolean;
alter table roles add column requestingunit boolean;
alter table roles add column contractingunit boolean;
alter table roles add column technicalunit boolean;


-- Ejecutar para crear tablas de project
/*
sequelize db:migrate
sequelize db:seed:all 
*/

-- Ejecutar para eliminar project

/*
sequelize db:migrate:undo:all
*/
