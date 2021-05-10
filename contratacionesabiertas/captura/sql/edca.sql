--
-- PostgreSQL database dump
--

-- Dumped from database version 10.11
-- Dumped by pg_dump version 10.11

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: clone_schema(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.clone_schema(source_schema text, dest_schema text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
object text;
buffer text;
default_ text;
column_ text;
constraint_name_ text;
constraint_def_ text;
trigger_name_ text; 
trigger_timing_ text; 
trigger_events_ text; 
trigger_orientation_ text;
trigger_action_ text;
owner_ text := 'prueba_dashboard';
BEGIN
	-- replace existing schema
	EXECUTE 'DROP SCHEMA IF EXISTS ' || dest_schema || ' CASCADE';
	-- create schema
	EXECUTE 'CREATE SCHEMA ' || dest_schema || ' AUTHORIZATION ' || owner_ ;
	-- create sequences
	FOR object IN
		SELECT sequence_name::text FROM information_schema.SEQUENCES WHERE sequence_schema = source_schema
		LOOP
			EXECUTE 'CREATE SEQUENCE ' || dest_schema || '.' || object;
END LOOP;

-- create tables
FOR object IN
	SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema
	LOOP
		buffer := dest_schema || '.' || object;
		-- create table
		EXECUTE 'CREATE TABLE ' || buffer || ' (LIKE ' || source_schema || '.' || object || ' INCLUDING CONSTRAINTS INCLUDING INDEXES INCLUDING DEFAULTS)';
		-- fix sequence defaults
		FOR column_, default_ IN
			SELECT column_name::text, REPLACE(column_default::text, source_schema||'.', dest_schema||'.') FROM information_schema.COLUMNS WHERE table_schema = dest_schema AND table_name = object AND column_default LIKE 'nextval(%' || source_schema || '.%::regclass)'
			LOOP
				EXECUTE 'ALTER TABLE ' || buffer || ' ALTER COLUMN ' || column_ || ' SET DEFAULT ' || default_;
      END LOOP;
  -- create triggers
  FOR trigger_name_, trigger_timing_, trigger_events_, trigger_orientation_, trigger_action_ IN
    SELECT trigger_name::text, action_timing::text, string_agg(event_manipulation::text, ' OR '), action_orientation::text, action_statement::text FROM information_schema.TRIGGERS WHERE event_object_schema=source_schema and event_object_table=object GROUP BY trigger_name, action_timing, action_orientation, action_statement
      LOOP
        EXECUTE 'CREATE TRIGGER ' || trigger_name_ || ' ' || trigger_timing_ || ' ' || trigger_events_ || ' ON ' || buffer || ' FOR EACH ' || trigger_orientation_ || ' ' || trigger_action_;
    END LOOP;
END LOOP;
-- reiterate tables and create foreign keys
FOR object IN
	SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema
	LOOP
		buffer := dest_schema || '.' || object;
		-- create foreign keys
		FOR constraint_name_, constraint_def_ IN
			SELECT conname::text, 
      CASE WHEN position( source_schema||'.' in pg_get_constraintdef(pg_constraint.oid)) = 0 THEN 
		  	REPLACE(pg_get_constraintdef(pg_constraint.oid), 'REFERENCES ', 'REFERENCES '|| dest_schema ||'.') 
        ELSE
        REPLACE(pg_get_constraintdef(pg_constraint.oid), source_schema ||'.', dest_schema||'.')
  	  END
      FROM pg_constraint INNER JOIN pg_class ON conrelid=pg_class.oid INNER JOIN pg_namespace ON pg_namespace.oid=pg_class.relnamespace WHERE contype='f' and relname=object and nspname=source_schema
			LOOP
				EXECUTE 'ALTER TABLE '|| buffer ||' ADD CONSTRAINT '|| constraint_name_ ||' '|| constraint_def_;
      END LOOP;
  EXECUTE 'ALTER TABLE ' || buffer || ' OWNER TO ' || owner_;
  END LOOP;
END;

$$;


--
-- Name: sp_test_gdmx(integer, integer, json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sp_test_gdmx(cp integer, id integer, record json) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO log_gdmx(date, cp, recordid, record)
  VALUES(now(), cp, id,record);
  return;
end; $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: additionalcontactpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.additionalcontactpoints (
    id integer NOT NULL,
    party_id integer,
    type text,
    name text,
    givenname text,
    surname text,
    additionalsurname text,
    email text,
    telephone text,
    faxnumber text,
    url text,
    language text
);


--
-- Name: additionalcontactpoints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.additionalcontactpoints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: additionalcontactpoints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.additionalcontactpoints_id_seq OWNED BY public.additionalcontactpoints.id;


--
-- Name: award; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.award (
    id integer NOT NULL,
    contractingprocess_id integer,
    awardid text,
    title text,
    description text,
    rationale text,
    status text,
    award_date timestamp without time zone,
    value_amount numeric,
    value_currency text,
    contractperiod_startdate timestamp without time zone,
    contractperiod_enddate timestamp without time zone,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    value_amountnet numeric,
    datelastupdate timestamp without time zone
);


--
-- Name: award_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.award_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: award_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.award_id_seq OWNED BY public.award.id;


--
-- Name: awardamendmentchanges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.awardamendmentchanges (
    id integer NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    property text,
    former_value text,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


--
-- Name: awardamendmentchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.awardamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: awardamendmentchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.awardamendmentchanges_id_seq OWNED BY public.awardamendmentchanges.id;


--
-- Name: awarddocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.awarddocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: awarddocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.awarddocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: awarddocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.awarddocuments_id_seq OWNED BY public.awarddocuments.id;


--
-- Name: awarditem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.awarditem (
    id integer NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


--
-- Name: awarditem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.awarditem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: awarditem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.awarditem_id_seq OWNED BY public.awarditem.id;


--
-- Name: awarditemadditionalclassifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.awarditemadditionalclassifications (
    id integer NOT NULL,
    award_id integer,
    awarditem_id integer,
    scheme text,
    description text,
    uri text
);


--
-- Name: awarditemadditionalclassifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.awarditemadditionalclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: awarditemadditionalclassifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.awarditemadditionalclassifications_id_seq OWNED BY public.awarditemadditionalclassifications.id;


--
-- Name: awardsupplier; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.awardsupplier (
    id integer NOT NULL,
    award_id integer,
    parties_id integer
);


--
-- Name: awardsupplier_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.awardsupplier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: awardsupplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.awardsupplier_id_seq OWNED BY public.awardsupplier.id;


--
-- Name: budget; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budget (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    budget_source text,
    budget_budgetid text,
    budget_description text,
    budget_amount numeric,
    budget_currency text,
    budget_project text,
    budget_projectid text,
    budget_uri text
);


--
-- Name: budget_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.budget_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: budget_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.budget_id_seq OWNED BY public.budget.id;


--
-- Name: budgetbreakdown; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budgetbreakdown (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    budgetbreakdown_id text,
    description text,
    amount numeric,
    currency text,
    url text,
    budgetbreakdownperiod_startdate timestamp without time zone,
    budgetbreakdownperiod_enddate timestamp without time zone,
    source_id integer,
    origin character varying,
    fund_type character varying
);


--
-- Name: budgetbreakdown_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.budgetbreakdown_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: budgetbreakdown_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.budgetbreakdown_id_seq OWNED BY public.budgetbreakdown.id;


--
-- Name: budgetclassifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budgetclassifications (
    id integer NOT NULL,
    budgetbreakdown_id integer,
    year integer,
    branch text,
    responsibleunit text,
    finality text,
    function text,
    subfunction text,
    institutionalactivity text,
    budgetprogram text,
    strategicobjective text,
    requestingunit text,
    specificactivity text,
    spendingobject text,
    spendingtype text,
    budgetsource text,
    region text,
    portfoliokey text,
    cve text,
    approved numeric,
    modified numeric,
    executed numeric,
    committed numeric,
    reserved numeric,
    trimester integer
);


--
-- Name: budgetclassifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.budgetclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: budgetclassifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.budgetclassifications_id_seq OWNED BY public.budgetclassifications.id;


--
-- Name: clarificationmeeting; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clarificationmeeting (
    id integer NOT NULL,
    clarificationmeetingid text,
    contractingprocess_id integer,
    date timestamp without time zone
);


--
-- Name: clarificationmeeting_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clarificationmeeting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clarificationmeeting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clarificationmeeting_id_seq OWNED BY public.clarificationmeeting.id;


--
-- Name: clarificationmeetingactor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clarificationmeetingactor (
    id integer NOT NULL,
    clarificationmeeting_id integer,
    parties_id integer,
    attender boolean,
    official boolean
);


--
-- Name: clarificationmeetingactor_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clarificationmeetingactor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clarificationmeetingactor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clarificationmeetingactor_id_seq OWNED BY public.clarificationmeetingactor.id;


--
-- Name: contract; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contract (
    id integer NOT NULL,
    contractingprocess_id integer,
    awardid text,
    contractid text,
    title text,
    description text,
    status text,
    period_startdate timestamp without time zone,
    period_enddate timestamp without time zone,
    value_amount numeric,
    value_currency text,
    datesigned timestamp without time zone,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    value_amountnet numeric,
    exchangerate_rate numeric,
    exchangerate_amount numeric DEFAULT 0,
    exchangerate_currency text,
    exchangerate_date timestamp without time zone,
    exchangerate_source text,
    datelastupdate timestamp without time zone,
    surveillancemechanisms text
);


--
-- Name: contract_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contract_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contract_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contract_id_seq OWNED BY public.contract.id;


--
-- Name: contractamendmentchanges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contractamendmentchanges (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


--
-- Name: contractamendmentchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contractamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contractamendmentchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contractamendmentchanges_id_seq OWNED BY public.contractamendmentchanges.id;


--
-- Name: contractdocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contractdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: contractdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contractdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contractdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contractdocuments_id_seq OWNED BY public.contractdocuments.id;


--
-- Name: contractingprocess; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contractingprocess (
    id integer NOT NULL,
    ocid text,
    description text,
    destino text,
    fecha_creacion date,
    hora_creacion time without time zone,
    stage integer,
    uri text,
    publicationpolicy text,
    license text,
    awardstatus text,
    contractstatus text,
    implementationstatus text,
    published boolean,
    valid boolean,
    date_published timestamp without time zone,
    requirepntupdate boolean,
    pnt_dateupdate timestamp without time zone,
    publisher text,
    updated boolean,
    updated_date timestamp without time zone,
    updated_version text,
    published_version text,
    pnt_published boolean,
    pnt_version text,
    pnt_date timestamp without time zone
);


--
-- Name: contractingprocess_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contractingprocess_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contractingprocess_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contractingprocess_id_seq OWNED BY public.contractingprocess.id;


--
-- Name: contractitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contractitem (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


--
-- Name: contractitem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contractitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contractitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contractitem_id_seq OWNED BY public.contractitem.id;


--
-- Name: contractitemadditionalclasifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contractitemadditionalclasifications (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    contractitem_id integer,
    scheme text,
    description text,
    uri text
);


--
-- Name: contractitemadditionalclasifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contractitemadditionalclasifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contractitemadditionalclasifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contractitemadditionalclasifications_id_seq OWNED BY public.contractitemadditionalclasifications.id;


--
-- Name: currency; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currency (
    id integer NOT NULL,
    entity text,
    currency text,
    currency_eng text,
    alphabetic_code text,
    numeric_code text,
    minor_unit text
);


--
-- Name: currency_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.currency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.currency_id_seq OWNED BY public.currency.id;


--
-- Name: datapnt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.datapnt (
    id integer NOT NULL,
    contractingprocess_id integer,
    fiscalyear integer,
    reportingperiodstartdate timestamp without time zone,
    reportingperiodenddate timestamp without time zone,
    dataresponsibleunit text,
    valitationdate timestamp without time zone,
    updatedate timestamp without time zone,
    notes text,
    data_pnt boolean
);


--
-- Name: datapnt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.datapnt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datapnt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.datapnt_id_seq OWNED BY public.datapnt.id;


--
-- Name: documentformat; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documentformat (
    id integer NOT NULL,
    category text,
    name text,
    template text,
    reference text
);


--
-- Name: documentformat_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documentformat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documentformat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documentformat_id_seq OWNED BY public.documentformat.id;


--
-- Name: documentmanagement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documentmanagement (
    id integer NOT NULL,
    contractingprocess_id integer,
    origin text,
    document text,
    instance_id text,
    type text,
    register_date timestamp without time zone,
    error text
);


--
-- Name: documentmanagement_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documentmanagement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documentmanagement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documentmanagement_id_seq OWNED BY public.documentmanagement.id;


--
-- Name: documenttype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documenttype (
    id integer NOT NULL,
    category text,
    code text,
    title text,
    title_esp text,
    description text,
    source text,
    stage integer
);


--
-- Name: documenttype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documenttype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documenttype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documenttype_id_seq OWNED BY public.documenttype.id;


--
-- Name: gdmx_dictionary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gdmx_dictionary (
    id integer NOT NULL,
    document text,
    variable text,
    tablename text,
    field text,
    parent text,
    type text,
    index integer,
    classification text,
    catalog text,
    catalog_field text,
    storeprocedure text
);


--
-- Name: gdmx_dictionary_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gdmx_dictionary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gdmx_dictionary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gdmx_dictionary_id_seq OWNED BY public.gdmx_dictionary.id;


--
-- Name: gdmx_document; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gdmx_document (
    id integer NOT NULL,
    name text,
    stage integer,
    type text,
    tablename text,
    identifier text
);


--
-- Name: gdmx_document_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gdmx_document_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gdmx_document_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gdmx_document_id_seq OWNED BY public.gdmx_document.id;


--
-- Name: guarantees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.guarantees (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    guarantee_id text,
    type text,
    date timestamp without time zone,
    obligations text,
    value numeric,
    guarantor integer,
    guaranteeperiod_startdate timestamp without time zone,
    guaranteeperiod_enddate timestamp without time zone,
    currency text
);


--
-- Name: guarantees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.guarantees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: guarantees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.guarantees_id_seq OWNED BY public.guarantees.id;


--
-- Name: implementation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementation (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    status text,
    datelastupdate timestamp without time zone
);


--
-- Name: implementation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementation_id_seq OWNED BY public.implementation.id;


--
-- Name: implementationdocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementationdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: implementationdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementationdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementationdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementationdocuments_id_seq OWNED BY public.implementationdocuments.id;


--
-- Name: implementationmilestone; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementationmilestone (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    milestoneid text,
    title text,
    description text,
    duedate timestamp without time zone,
    date_modified timestamp without time zone,
    status text,
    type text
);


--
-- Name: implementationmilestone_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementationmilestone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementationmilestone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementationmilestone_id_seq OWNED BY public.implementationmilestone.id;


--
-- Name: implementationmilestonedocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementationmilestonedocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: implementationmilestonedocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementationmilestonedocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementationmilestonedocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementationmilestonedocuments_id_seq OWNED BY public.implementationmilestonedocuments.id;


--
-- Name: implementationstatus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementationstatus (
    id integer NOT NULL,
    code text,
    title text,
    title_esp text,
    description text
);


--
-- Name: implementationstatus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementationstatus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementationstatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementationstatus_id_seq OWNED BY public.implementationstatus.id;


--
-- Name: implementationtransactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementationtransactions (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    transactionid text,
    source text,
    implementation_date timestamp without time zone,
    value_amount numeric,
    value_currency text,
    payment_method text,
    uri text,
    payer_name text,
    payer_id text,
    payee_name text,
    payee_id text,
    value_amountnet numeric
);


--
-- Name: implementationtransactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementationtransactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementationtransactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementationtransactions_id_seq OWNED BY public.implementationtransactions.id;


--
-- Name: item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item (
    id integer NOT NULL,
    classificationid text NOT NULL,
    description text NOT NULL,
    unit text
);


--
-- Name: item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_id_seq OWNED BY public.item.id;


--
-- Name: language; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.language (
    id integer NOT NULL,
    alpha2 character varying(2),
    name text
);


--
-- Name: language_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.language_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: language_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.language_id_seq OWNED BY public.language.id;


--
-- Name: links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.links (
    id integer NOT NULL,
    json text,
    xlsx text,
    pdf text,
    contractingprocess_id integer
);


--
-- Name: links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.links_id_seq OWNED BY public.links.id;


--
-- Name: log_gdmx; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_gdmx (
    id integer NOT NULL,
    date timestamp without time zone,
    cp integer,
    recordid integer,
    record json
);


--
-- Name: log_gdmx_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_gdmx_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_gdmx_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_gdmx_id_seq OWNED BY public.log_gdmx.id;


--
-- Name: logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logs (
    id integer NOT NULL,
    version text,
    update_date timestamp without time zone,
    publisher text,
    release_file text,
    release_json json,
    record_json json,
    contractingprocess_id integer,
    version_json json,
    published boolean
);


--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.logs_id_seq OWNED BY public.logs.id;


--
-- Name: memberof; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memberof (
    id integer NOT NULL,
    memberofid text,
    principal_parties_id integer,
    parties_id integer
);


--
-- Name: memberof_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.memberof_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberof_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.memberof_id_seq OWNED BY public.memberof.id;


--
-- Name: metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metadata (
    field_name character varying(50) NOT NULL,
    value text
);


--
-- Name: milestonetype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.milestonetype (
    id integer NOT NULL,
    code text,
    title text,
    description text
);


--
-- Name: milestonetype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.milestonetype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: milestonetype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.milestonetype_id_seq OWNED BY public.milestonetype.id;


--
-- Name: parties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parties (
    contractingprocess_id integer,
    id integer NOT NULL,
    partyid text,
    name text,
    "position" text,
    identifier_scheme text,
    identifier_id text,
    identifier_legalname text,
    identifier_uri text,
    address_streetaddress text,
    address_locality text,
    address_region text,
    address_postalcode text,
    address_countryname text,
    contactpoint_name text,
    contactpoint_email text,
    contactpoint_telephone text,
    contactpoint_faxnumber text,
    contactpoint_url text,
    details text,
    naturalperson boolean,
    contactpoint_type text,
    contactpoint_language text,
    surname text,
    additionalsurname text,
    contactpoint_surname text,
    contactpoint_additionalsurname text,
    givenname text,
    contactpoint_givenname text
);


--
-- Name: parties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parties_id_seq OWNED BY public.parties.id;


--
-- Name: partiesadditionalidentifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partiesadditionalidentifiers (
    id integer NOT NULL,
    contractingprocess_id integer,
    parties_id integer,
    scheme text,
    legalname text,
    uri text
);


--
-- Name: partiesadditionalidentifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.partiesadditionalidentifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: partiesadditionalidentifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.partiesadditionalidentifiers_id_seq OWNED BY public.partiesadditionalidentifiers.id;


--
-- Name: paymentmethod; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.paymentmethod (
    id integer NOT NULL,
    code text,
    title text,
    description text
);


--
-- Name: paymentmethod_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.paymentmethod_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: paymentmethod_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.paymentmethod_id_seq OWNED BY public.paymentmethod.id;


--
-- Name: planning; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planning (
    id integer NOT NULL,
    contractingprocess_id integer,
    hasquotes boolean,
    rationale text,
    numberofbeneficiaries numeric
);


--
-- Name: planning_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.planning_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planning_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.planning_id_seq OWNED BY public.planning.id;


--
-- Name: planningdocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planningdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    documentid text,
    document_type text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: planningdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.planningdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planningdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.planningdocuments_id_seq OWNED BY public.planningdocuments.id;


--
-- Name: pntreference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pntreference (
    id integer NOT NULL,
    contractingprocess_id integer,
    contractid text,
    format integer,
    record_id text,
    "position" integer,
    field_id integer,
    reference_id integer,
    date timestamp without time zone,
    isroot boolean,
    error text
);


--
-- Name: pntreference_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pntreference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pntreference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pntreference_id_seq OWNED BY public.pntreference.id;


--
-- Name: prefixocid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prefixocid (
    id integer NOT NULL,
    value text
);


--
-- Name: prefixocid_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prefixocid_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prefixocid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prefixocid_id_seq OWNED BY public.prefixocid.id;


--
-- Name: programaticstructure; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programaticstructure (
    id integer NOT NULL,
    cve text,
    year integer,
    trimester integer,
    branch text,
    branch_desc text,
    finality text,
    finality_desc text,
    function text,
    function_desc text,
    subfunction text,
    subfunction_desc text,
    institutionalactivity text,
    institutionalactivity_desc text,
    budgetprogram text,
    budgetprogram_desc text,
    strategicobjective text,
    strategicobjective_desc text,
    responsibleunit text,
    responsibleunit_desc text,
    requestingunit text,
    requestingunit_desc text,
    spendingtype text,
    spendingtype_desc text,
    specificactivity text,
    specificactivity_desc text,
    spendingobject text,
    spendingobject_desc text,
    region text,
    region_desc text,
    budgetsource text,
    budgetsource_desc text,
    portfoliokey text,
    approvedamount numeric,
    modifiedamount numeric,
    executedamount numeric,
    committedamount numeric,
    reservedamount numeric
);


--
-- Name: programaticstructure_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.programaticstructure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: programaticstructure_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.programaticstructure_id_seq OWNED BY public.programaticstructure.id;


--
-- Name: publisher; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.publisher (
    id integer NOT NULL,
    contractingprocess_id integer,
    name text,
    scheme text,
    uid text,
    uri text
);


--
-- Name: publisher_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.publisher_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: publisher_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.publisher_id_seq OWNED BY public.publisher.id;


--
-- Name: quotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quotes (
    id integer NOT NULL,
    requestforquotes_id integer,
    quotes_id text,
    description text,
    date timestamp without time zone,
    value numeric,
    quoteperiod_startdate timestamp without time zone,
    quoteperiod_enddate timestamp without time zone,
    issuingsupplier_id integer
);


--
-- Name: quotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quotes_id_seq OWNED BY public.quotes.id;


--
-- Name: quotesitems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quotesitems (
    id integer NOT NULL,
    quotes_id integer,
    itemid text,
    item text,
    quantity numeric
);


--
-- Name: quotesitems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quotesitems_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quotesitems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quotesitems_id_seq OWNED BY public.quotesitems.id;


--
-- Name: relatedprocedure; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relatedprocedure (
    id integer NOT NULL,
    contractingprocess_id integer,
    relatedprocedure_id text,
    relationship_type text,
    title text,
    identifier_scheme text,
    relatedprocedure_identifier text,
    url text
);


--
-- Name: relatedprocedure_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.relatedprocedure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relatedprocedure_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.relatedprocedure_id_seq OWNED BY public.relatedprocedure.id;


--
-- Name: requestforquotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requestforquotes (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    requestforquotes_id text,
    title text,
    description text,
    period_startdate timestamp without time zone,
    period_enddate timestamp without time zone
);


--
-- Name: requestforquotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.requestforquotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: requestforquotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.requestforquotes_id_seq OWNED BY public.requestforquotes.id;


--
-- Name: requestforquotesinvitedsuppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requestforquotesinvitedsuppliers (
    id integer NOT NULL,
    requestforquotes_id integer,
    parties_id integer
);


--
-- Name: requestforquotesinvitedsuppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.requestforquotesinvitedsuppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: requestforquotesinvitedsuppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.requestforquotesinvitedsuppliers_id_seq OWNED BY public.requestforquotesinvitedsuppliers.id;


--
-- Name: requestforquotesitems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requestforquotesitems (
    id integer NOT NULL,
    requestforquotes_id integer,
    itemid text,
    item text,
    quantity integer
);


--
-- Name: requestforquotesitems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.requestforquotesitems_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: requestforquotesitems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.requestforquotesitems_id_seq OWNED BY public.requestforquotesitems.id;


--
-- Name: rolecatalog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rolecatalog (
    id integer NOT NULL,
    code text,
    title text,
    description text
);


--
-- Name: rolecatalog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rolecatalog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rolecatalog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rolecatalog_id_seq OWNED BY public.rolecatalog.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    contractingprocess_id integer,
    parties_id integer,
    id integer NOT NULL,
    buyer boolean,
    procuringentity boolean,
    supplier boolean,
    tenderer boolean,
    funder boolean,
    enquirer boolean,
    payer boolean,
    payee boolean,
    reviewbody boolean,
    attendee boolean,
    official boolean,
    invitedsupplier boolean,
    issuingsupplier boolean,
    guarantor boolean,
    requestingunit boolean,
    contractingunit boolean,
    technicalunit boolean,
    responsibleunit boolean
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning boolean,
    planningupdate boolean,
    tender boolean,
    tenderamendment boolean,
    tenderupdate boolean,
    tendercancellation boolean,
    award boolean,
    awardupdate boolean,
    awardcancellation boolean,
    contract boolean,
    contractupdate boolean,
    contractamendment boolean,
    implementation boolean,
    implementationupdate boolean,
    contracttermination boolean,
    compiled boolean,
    stage integer,
    register_date timestamp without time zone
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: tender; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tender (
    id integer NOT NULL,
    contractingprocess_id integer,
    tenderid text,
    title text,
    description text,
    status text,
    minvalue_amount numeric,
    minvalue_currency text,
    value_amount numeric,
    value_currency text,
    procurementmethod text,
    procurementmethod_details text,
    procurementmethod_rationale text,
    mainprocurementcategory text,
    additionalprocurementcategories text,
    awardcriteria text,
    awardcriteria_details text,
    submissionmethod text,
    submissionmethod_details text,
    tenderperiod_startdate timestamp without time zone,
    tenderperiod_enddate timestamp without time zone,
    enquiryperiod_startdate timestamp without time zone,
    enquiryperiod_enddate timestamp without time zone,
    hasenquiries boolean,
    eligibilitycriteria text,
    awardperiod_startdate timestamp without time zone,
    awardperiod_enddate timestamp without time zone,
    numberoftenderers integer,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    procurementmethod_rationale_id text
);


--
-- Name: tender_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tender_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tender_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tender_id_seq OWNED BY public.tender.id;


--
-- Name: tenderamendmentchanges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenderamendmentchanges (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    property text,
    former_value text,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


--
-- Name: tenderamendmentchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenderamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenderamendmentchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenderamendmentchanges_id_seq OWNED BY public.tenderamendmentchanges.id;


--
-- Name: tenderdocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenderdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: tenderdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenderdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenderdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenderdocuments_id_seq OWNED BY public.tenderdocuments.id;


--
-- Name: tenderitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenderitem (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


--
-- Name: tenderitem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenderitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenderitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenderitem_id_seq OWNED BY public.tenderitem.id;


--
-- Name: tenderitemadditionalclassifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenderitemadditionalclassifications (
    id integer NOT NULL,
    contractingprocess_id integer,
    tenderitem_id integer,
    scheme text,
    description text,
    uri text
);


--
-- Name: tenderitemadditionalclassifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenderitemadditionalclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenderitemadditionalclassifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenderitemadditionalclassifications_id_seq OWNED BY public.tenderitemadditionalclassifications.id;


--
-- Name: tendermilestone; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tendermilestone (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    milestoneid text,
    title text,
    description text,
    duedate timestamp without time zone,
    date_modified timestamp without time zone,
    status text,
    type text
);


--
-- Name: tendermilestone_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tendermilestone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tendermilestone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tendermilestone_id_seq OWNED BY public.tendermilestone.id;


--
-- Name: tendermilestonedocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tendermilestonedocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    milestone_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: tendermilestonedocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tendermilestonedocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tendermilestonedocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tendermilestonedocuments_id_seq OWNED BY public.tendermilestonedocuments.id;


--
-- Name: user_contractingprocess; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_contractingprocess (
    id integer NOT NULL,
    user_id text,
    contractingprocess_id integer
);


--
-- Name: user_contractingprocess_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_contractingprocess_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_contractingprocess_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_contractingprocess_id_seq OWNED BY public.user_contractingprocess.id;


--
-- Name: additionalcontactpoints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.additionalcontactpoints ALTER COLUMN id SET DEFAULT nextval('public.additionalcontactpoints_id_seq'::regclass);


--
-- Name: award id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.award ALTER COLUMN id SET DEFAULT nextval('public.award_id_seq'::regclass);


--
-- Name: awardamendmentchanges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardamendmentchanges ALTER COLUMN id SET DEFAULT nextval('public.awardamendmentchanges_id_seq'::regclass);


--
-- Name: awarddocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarddocuments ALTER COLUMN id SET DEFAULT nextval('public.awarddocuments_id_seq'::regclass);


--
-- Name: awarditem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditem ALTER COLUMN id SET DEFAULT nextval('public.awarditem_id_seq'::regclass);


--
-- Name: awarditemadditionalclassifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditemadditionalclassifications ALTER COLUMN id SET DEFAULT nextval('public.awarditemadditionalclassifications_id_seq'::regclass);


--
-- Name: awardsupplier id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardsupplier ALTER COLUMN id SET DEFAULT nextval('public.awardsupplier_id_seq'::regclass);


--
-- Name: budget id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget ALTER COLUMN id SET DEFAULT nextval('public.budget_id_seq'::regclass);


--
-- Name: budgetbreakdown id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgetbreakdown ALTER COLUMN id SET DEFAULT nextval('public.budgetbreakdown_id_seq'::regclass);


--
-- Name: budgetclassifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgetclassifications ALTER COLUMN id SET DEFAULT nextval('public.budgetclassifications_id_seq'::regclass);


--
-- Name: clarificationmeeting id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeeting ALTER COLUMN id SET DEFAULT nextval('public.clarificationmeeting_id_seq'::regclass);


--
-- Name: clarificationmeetingactor id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeetingactor ALTER COLUMN id SET DEFAULT nextval('public.clarificationmeetingactor_id_seq'::regclass);


--
-- Name: contract id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract ALTER COLUMN id SET DEFAULT nextval('public.contract_id_seq'::regclass);


--
-- Name: contractamendmentchanges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractamendmentchanges ALTER COLUMN id SET DEFAULT nextval('public.contractamendmentchanges_id_seq'::regclass);


--
-- Name: contractdocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractdocuments ALTER COLUMN id SET DEFAULT nextval('public.contractdocuments_id_seq'::regclass);


--
-- Name: contractingprocess id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractingprocess ALTER COLUMN id SET DEFAULT nextval('public.contractingprocess_id_seq'::regclass);


--
-- Name: contractitem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitem ALTER COLUMN id SET DEFAULT nextval('public.contractitem_id_seq'::regclass);


--
-- Name: contractitemadditionalclasifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitemadditionalclasifications ALTER COLUMN id SET DEFAULT nextval('public.contractitemadditionalclasifications_id_seq'::regclass);


--
-- Name: currency id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency ALTER COLUMN id SET DEFAULT nextval('public.currency_id_seq'::regclass);


--
-- Name: datapnt id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datapnt ALTER COLUMN id SET DEFAULT nextval('public.datapnt_id_seq'::regclass);


--
-- Name: documentformat id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentformat ALTER COLUMN id SET DEFAULT nextval('public.documentformat_id_seq'::regclass);


--
-- Name: documentmanagement id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentmanagement ALTER COLUMN id SET DEFAULT nextval('public.documentmanagement_id_seq'::regclass);


--
-- Name: documenttype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype ALTER COLUMN id SET DEFAULT nextval('public.documenttype_id_seq'::regclass);


--
-- Name: gdmx_dictionary id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gdmx_dictionary ALTER COLUMN id SET DEFAULT nextval('public.gdmx_dictionary_id_seq'::regclass);


--
-- Name: gdmx_document id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gdmx_document ALTER COLUMN id SET DEFAULT nextval('public.gdmx_document_id_seq'::regclass);


--
-- Name: guarantees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guarantees ALTER COLUMN id SET DEFAULT nextval('public.guarantees_id_seq'::regclass);


--
-- Name: implementation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementation ALTER COLUMN id SET DEFAULT nextval('public.implementation_id_seq'::regclass);


--
-- Name: implementationdocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationdocuments ALTER COLUMN id SET DEFAULT nextval('public.implementationdocuments_id_seq'::regclass);


--
-- Name: implementationmilestone id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestone ALTER COLUMN id SET DEFAULT nextval('public.implementationmilestone_id_seq'::regclass);


--
-- Name: implementationmilestonedocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestonedocuments ALTER COLUMN id SET DEFAULT nextval('public.implementationmilestonedocuments_id_seq'::regclass);


--
-- Name: implementationstatus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationstatus ALTER COLUMN id SET DEFAULT nextval('public.implementationstatus_id_seq'::regclass);


--
-- Name: implementationtransactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationtransactions ALTER COLUMN id SET DEFAULT nextval('public.implementationtransactions_id_seq'::regclass);


--
-- Name: item id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item ALTER COLUMN id SET DEFAULT nextval('public.item_id_seq'::regclass);


--
-- Name: language id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language ALTER COLUMN id SET DEFAULT nextval('public.language_id_seq'::regclass);


--
-- Name: links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links ALTER COLUMN id SET DEFAULT nextval('public.links_id_seq'::regclass);


--
-- Name: log_gdmx id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_gdmx ALTER COLUMN id SET DEFAULT nextval('public.log_gdmx_id_seq'::regclass);


--
-- Name: logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs ALTER COLUMN id SET DEFAULT nextval('public.logs_id_seq'::regclass);


--
-- Name: memberof id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberof ALTER COLUMN id SET DEFAULT nextval('public.memberof_id_seq'::regclass);


--
-- Name: milestonetype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.milestonetype ALTER COLUMN id SET DEFAULT nextval('public.milestonetype_id_seq'::regclass);


--
-- Name: parties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parties ALTER COLUMN id SET DEFAULT nextval('public.parties_id_seq'::regclass);


--
-- Name: partiesadditionalidentifiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiesadditionalidentifiers ALTER COLUMN id SET DEFAULT nextval('public.partiesadditionalidentifiers_id_seq'::regclass);


--
-- Name: paymentmethod id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paymentmethod ALTER COLUMN id SET DEFAULT nextval('public.paymentmethod_id_seq'::regclass);


--
-- Name: planning id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning ALTER COLUMN id SET DEFAULT nextval('public.planning_id_seq'::regclass);


--
-- Name: planningdocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planningdocuments ALTER COLUMN id SET DEFAULT nextval('public.planningdocuments_id_seq'::regclass);


--
-- Name: pntreference id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pntreference ALTER COLUMN id SET DEFAULT nextval('public.pntreference_id_seq'::regclass);


--
-- Name: prefixocid id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prefixocid ALTER COLUMN id SET DEFAULT nextval('public.prefixocid_id_seq'::regclass);


--
-- Name: programaticstructure id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programaticstructure ALTER COLUMN id SET DEFAULT nextval('public.programaticstructure_id_seq'::regclass);


--
-- Name: publisher id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publisher ALTER COLUMN id SET DEFAULT nextval('public.publisher_id_seq'::regclass);


--
-- Name: quotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes ALTER COLUMN id SET DEFAULT nextval('public.quotes_id_seq'::regclass);


--
-- Name: quotesitems id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotesitems ALTER COLUMN id SET DEFAULT nextval('public.quotesitems_id_seq'::regclass);


--
-- Name: relatedprocedure id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relatedprocedure ALTER COLUMN id SET DEFAULT nextval('public.relatedprocedure_id_seq'::regclass);


--
-- Name: requestforquotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotes ALTER COLUMN id SET DEFAULT nextval('public.requestforquotes_id_seq'::regclass);


--
-- Name: requestforquotesinvitedsuppliers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers ALTER COLUMN id SET DEFAULT nextval('public.requestforquotesinvitedsuppliers_id_seq'::regclass);


--
-- Name: requestforquotesitems id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesitems ALTER COLUMN id SET DEFAULT nextval('public.requestforquotesitems_id_seq'::regclass);


--
-- Name: rolecatalog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rolecatalog ALTER COLUMN id SET DEFAULT nextval('public.rolecatalog_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tender id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tender ALTER COLUMN id SET DEFAULT nextval('public.tender_id_seq'::regclass);


--
-- Name: tenderamendmentchanges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderamendmentchanges ALTER COLUMN id SET DEFAULT nextval('public.tenderamendmentchanges_id_seq'::regclass);


--
-- Name: tenderdocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderdocuments ALTER COLUMN id SET DEFAULT nextval('public.tenderdocuments_id_seq'::regclass);


--
-- Name: tenderitem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitem ALTER COLUMN id SET DEFAULT nextval('public.tenderitem_id_seq'::regclass);


--
-- Name: tenderitemadditionalclassifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications ALTER COLUMN id SET DEFAULT nextval('public.tenderitemadditionalclassifications_id_seq'::regclass);


--
-- Name: tendermilestone id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestone ALTER COLUMN id SET DEFAULT nextval('public.tendermilestone_id_seq'::regclass);


--
-- Name: tendermilestonedocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestonedocuments ALTER COLUMN id SET DEFAULT nextval('public.tendermilestonedocuments_id_seq'::regclass);


--
-- Name: user_contractingprocess id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_contractingprocess ALTER COLUMN id SET DEFAULT nextval('public.user_contractingprocess_id_seq'::regclass);


--
-- Data for Name: additionalcontactpoints; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.additionalcontactpoints (id, party_id, type, name, givenname, surname, additionalsurname, email, telephone, faxnumber, url, language) FROM stdin;
\.


--
-- Data for Name: award; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.award (id, contractingprocess_id, awardid, title, description, rationale, status, award_date, value_amount, value_currency, contractperiod_startdate, contractperiod_enddate, amendment_date, amendment_rationale, value_amountnet, datelastupdate) FROM stdin;
\.


--
-- Data for Name: awardamendmentchanges; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.awardamendmentchanges (id, contractingprocess_id, award_id, property, former_value, amendments_date, amendments_rationale, amendments_id, amendments_description) FROM stdin;
\.


--
-- Data for Name: awarddocuments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.awarddocuments (id, contractingprocess_id, award_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: awarditem; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.awarditem (id, contractingprocess_id, award_id, itemid, description, classification_scheme, classification_id, classification_description, classification_uri, quantity, unit_name, unit_value_amount, unit_value_currency, unit_value_amountnet, latitude, longitude, location_postalcode, location_countryname, location_streetaddress, location_region, location_locality) FROM stdin;
\.


--
-- Data for Name: awarditemadditionalclassifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.awarditemadditionalclassifications (id, award_id, awarditem_id, scheme, description, uri) FROM stdin;
\.


--
-- Data for Name: awardsupplier; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.awardsupplier (id, award_id, parties_id) FROM stdin;
\.


--
-- Data for Name: budget; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.budget (id, contractingprocess_id, planning_id, budget_source, budget_budgetid, budget_description, budget_amount, budget_currency, budget_project, budget_projectid, budget_uri) FROM stdin;
\.


--
-- Data for Name: budgetbreakdown; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.budgetbreakdown (id, contractingprocess_id, planning_id, budgetbreakdown_id, description, amount, currency, url, budgetbreakdownperiod_startdate, budgetbreakdownperiod_enddate, source_id, origin, fund_type) FROM stdin;
\.


--
-- Data for Name: budgetclassifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.budgetclassifications (id, budgetbreakdown_id, year, branch, responsibleunit, finality, function, subfunction, institutionalactivity, budgetprogram, strategicobjective, requestingunit, specificactivity, spendingobject, spendingtype, budgetsource, region, portfoliokey, cve, approved, modified, executed, committed, reserved, trimester) FROM stdin;
\.


--
-- Data for Name: clarificationmeeting; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.clarificationmeeting (id, clarificationmeetingid, contractingprocess_id, date) FROM stdin;
\.


--
-- Data for Name: clarificationmeetingactor; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.clarificationmeetingactor (id, clarificationmeeting_id, parties_id, attender, official) FROM stdin;
\.


--
-- Data for Name: contract; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contract (id, contractingprocess_id, awardid, contractid, title, description, status, period_startdate, period_enddate, value_amount, value_currency, datesigned, amendment_date, amendment_rationale, value_amountnet, exchangerate_rate, exchangerate_amount, exchangerate_currency, exchangerate_date, exchangerate_source, datelastupdate, surveillancemechanisms) FROM stdin;
\.


--
-- Data for Name: contractamendmentchanges; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contractamendmentchanges (id, contractingprocess_id, contract_id, amendments_date, amendments_rationale, amendments_id, amendments_description) FROM stdin;
\.


--
-- Data for Name: contractdocuments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contractdocuments (id, contractingprocess_id, contract_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: contractingprocess; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contractingprocess (id, ocid, description, destino, fecha_creacion, hora_creacion, stage, uri, publicationpolicy, license, awardstatus, contractstatus, implementationstatus, published, valid, date_published, requirepntupdate, pnt_dateupdate, publisher, updated, updated_date, updated_version, published_version, pnt_published, pnt_version, pnt_date) FROM stdin;
\.


--
-- Data for Name: contractitem; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contractitem (id, contractingprocess_id, contract_id, itemid, description, classification_scheme, classification_id, classification_description, classification_uri, quantity, unit_name, unit_value_amount, unit_value_currency, unit_value_amountnet, latitude, longitude, location_postalcode, location_countryname, location_streetaddress, location_region, location_locality) FROM stdin;
\.


--
-- Data for Name: contractitemadditionalclasifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contractitemadditionalclasifications (id, contractingprocess_id, contract_id, contractitem_id, scheme, description, uri) FROM stdin;
\.


--
-- Data for Name: currency; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.currency (id, entity, currency, currency_eng, alphabetic_code, numeric_code, minor_unit) FROM stdin;
1	AFGHANISTAN	Afgano	Afghani	AFN	971	2
2	MADAGASCAR	Ariary malgache	Malagasy Ariary	MGA	969	2
3	ARUBA	Aruban Guilder	Aruban Florin	AWG	533	2
4	THAILAND	Bath	Baht	THB	764	2
5	PANAMA	Balboa	Balboa	PAB	590	2
6	BELARUS	Belarusian Ruble	Belarusian Ruble	BYR	974	0
7	ETHIOPIA	Birr etíope	Ethiopian Birr	ETB	230	2
8		Bitcoin	Bitcoin	XBT		
9	VENEZUELA (BOLIVARIAN REPUBLIC OF)	Bolívar	Bolívar	VEF	937	2
10	BOLIVIA (PLURINATIONAL STATE OF)	Boliviano	Boliviano	BOB	068	2
11	CABO VERDE	Cabo Verde Escudo	Cabo Verde Escudo	CVE	132	2
12	GHANA	Cedi	Ghana Cedi	GHS	936	2
13	BENIN	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
14	BURKINA FASO	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
15	CÔTE DIVOIRE	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
16	GUINEA-BISSAU	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
17	MALI	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
18	NIGER (THE)	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
19	SENEGAL	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
20	TOGO	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
21	CAMEROON	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
22	CENTRAL AFRICAN REPUBLIC (THE)	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
23	CHAD	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
24	CONGO (THE)	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
25	EQUATORIAL GUINEA	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
26	GABON	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
27	KENYA	Chelín de Kenia	Kenyan Shilling	KES	404	2
28	TANZANIA, UNITED REPUBLIC OF	Chelín de Tanzania	Tanzanian Shilling	TZS	834	2
29	SOMALIA	Chelín somalí	Somali Shilling	SOS	706	2
30	UGANDA	Chelín ungandés	Uganda Shilling	UGX	800	0
31	COSTA RICA	Colón de Costa Rica	Costa Rican Colon	CRC	188	2
32	EL SALVADOR	Colón de El Salvador	El Salvador Colon	SVC	222	2
33	COMOROS (THE)	Comoro Franc	Comoro Franc	KMF	174	0
34	BOSNIA AND HERZEGOVINA	Convertible Marks	Convertible Mark	BAM	977	2
35	NICARAGUA	Cordoba Oro	Cordoba Oro	NIO	558	2
36		Corona	Koruna	EEK		
37	CZECH REPUBLIC (THE)	Corona Checa	Czech Koruna	CZK	203	2
38	DENMARK	Corona danesa	Danish Krone	DKK	208	2
39	FAROE ISLANDS (THE)	Corona danesa	Danish Krone	DKK	208	2
40	GREENLAND	Corona danesa	Danish Krone	DKK	208	2
41	ICELAND	Corona de Islandia	Iceland Krona	ISK	352	0
42	BOUVET ISLAND	Corona noruega	Norwegian Krone	NOK	578	2
43	NORWAY	Corona noruega	Norwegian Krone	NOK	578	2
44	SVALBARD AND JAN MAYEN	Corona noruega	Norwegian Krone	NOK	578	2
45	SWEDEN	Corona sueca	Swedish Krona	SEK	752	2
46	GAMBIA (THE)	Dalasi	Dalasi	GMD	270	2
47	MACEDONIA (THE FORMER YUGOSLAV REPUBLIC OF)	Denar	Denar	MKD	807	2
48	ALGERIA	Dinar argelino	Algerian Dinar	DZD	012	2
49	BAHRAIN	Dinar de Bahrein	Bahraini Dinar	BHD	048	3
50	IRAQ	Dinar iraquí	Iraqi Dinar	IQD	368	3
51	JORDAN	Dinar jordano	Jordanian Dinar	JOD	400	3
52	KUWAIT	Dinar kuwaití	Kuwaiti Dinar	KWD	414	3
53	LIBYA	Dinar libio	Libyan Dinar	LYD	434	3
54	SERBIA	Dinar serbio	Serbian Dinar	RSD	941	2
55	TUNISIA	Dinar tunecino TOP Paanga	Tunisian Dinar	TND	788	3
56	UNITED ARAB EMIRATES (THE)	Dirham de los Emiratos Árabes Unidos	UAE Dirham	AED	784	2
57	MOROCCO	Dirham marroquí	Moroccan Dirham	MAD	504	2
58	WESTERN SAHARA	Dirham marroquí	Moroccan Dirham	MAD	504	2
59	SAO TOME AND PRINCIPE	Dobra	Dobra	STD	678	2
60	AUSTRALIA	Dólar australiano	Australian Dollar	AUD	036	2
61	CHRISTMAS ISLAND	Dólar australiano	Australian Dollar	AUD	036	2
62	COCOS (KEELING) ISLANDS (THE)	Dólar australiano	Australian Dollar	AUD	036	2
63	HEARD ISLAND AND McDONALD ISLANDS	Dólar australiano	Australian Dollar	AUD	036	2
64	KIRIBATI	Dólar australiano	Australian Dollar	AUD	036	2
65	NORFOLK ISLAND	Dólar australiano	Australian Dollar	AUD	036	2
66	NAURU	Dólar australiano	Australian Dollar	AUD	036	2
67	TUVALU	Dólar australiano	Australian Dollar	AUD	036	2
68	BERMUDA	Dólar bermudeño	Bermudian Dollar	BMD	060	2
69	CANADA	Dólar canadiense	Canadian Dollar	CAD	124	2
70	BARBADOS	Dólar de Barbados	Barbados Dollar	BBD	052	2
71	BELIZE	Dólar de Belice	Belize Dollar	BZD	084	2
72	BRUNEI DARUSSALAM	Dólar de Brunei	Brunei Dollar	BND	096	2
73	FIJI	Dólar de Fiji	Fiji Dollar	FJD	242	2
74	GUYANA	Dólar de Guyana	Guyana Dollar	GYD	328	2
75	HONG KONG	Dólar de Hong Kong	Hong Kong Dollar	HKD	344	2
76	BAHAMAS (THE)	Dólar de las Bahamas	Bahamian Dollar	BSD	044	2
77	CAYMAN ISLANDS (THE)	Dólar de las Islas Caimán	Cayman Islands Dollar	KYD	136	2
78	SOLOMON ISLANDS	Dólar de las Islas Salomón	Solomon Islands Dollar	SBD	090	2
79	NAMIBIA	Dólar de Namibia	Namibia Dollar	NAD	516	2
80	COOK ISLANDS (THE)	Dólar de Nueva Zelanda	New Zealand Dollar	NZD	554	2
81	NEW ZEALAND	Dólar de Nueva Zelanda	New Zealand Dollar	NZD	554	2
82	NIUE	Dólar de Nueva Zelanda	New Zealand Dollar	NZD	554	2
83	PITCAIRN	Dólar de Nueva Zelanda	New Zealand Dollar	NZD	554	2
84	TOKELAU	Dólar de Nueva Zelanda	New Zealand Dollar	NZD	554	2
85	SINGAPORE	Dólar de Singapur	Singapore Dollar	SGD	702	2
86	SURINAME	Dólar de Surinam	Surinam Dollar	SRD	968	2
87	TRINIDAD AND TOBAGO	Dólar de Trinidad y Tobago	Trinidad and Tobago Dollar	TTD	780	2
88	ZIMBABWE	Dólar de Zimbabwe	Zimbabwe Dollar	ZWL	932	2
89	ANGUILLA	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
90	ANTIGUA AND BARBUDA	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
91	DOMINICA	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
92	GRENADA	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
93	MONTSERRAT	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
94	SAINT KITTS AND NEVIS	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
95	SAINT LUCIA	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
96	SAINT VINCENT AND THE GRENADINES	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
97	AMERICAN SAMOA	Dólar estadounidense	US Dollar	USD	840	2
98	BONAIRE, SINT EUSTATIUS AND SABA	Dólar estadounidense	US Dollar	USD	840	2
99	BRITISH INDIAN OCEAN TERRITORY (THE)	Dólar estadounidense	US Dollar	USD	840	2
100	ECUADOR	Dólar estadounidense	US Dollar	USD	840	2
101	EL SALVADOR	Dólar estadounidense	US Dollar	USD	840	2
102	GUAM	Dólar estadounidense	US Dollar	USD	840	2
103	HAITI	Dólar estadounidense	US Dollar	USD	840	2
104	MARSHALL ISLANDS (THE)	Dólar estadounidense	US Dollar	USD	840	2
105	MICRONESIA (FEDERATED STATES OF)	Dólar estadounidense	US Dollar	USD	840	2
106	NORTHERN MARIANA ISLANDS (THE)	Dólar estadounidense	US Dollar	USD	840	2
107	PALAU	Dólar estadounidense	US Dollar	USD	840	2
108	PANAMA	Dólar estadounidense	US Dollar	USD	840	2
109	PUERTO RICO	Dólar estadounidense	US Dollar	USD	840	2
110	TIMOR-LESTE	Dólar estadounidense	US Dollar	USD	840	2
111	TURKS AND CAICOS ISLANDS (THE)	Dólar estadounidense	US Dollar	USD	840	2
112	UNITED STATES MINOR OUTLYING ISLANDS (THE)	Dólar estadounidense	US Dollar	USD	840	2
113	UNITED STATES OF AMERICA (THE)	Dólar estadounidense	US Dollar	USD	840	2
114	VIRGIN ISLANDS (BRITISH)	Dólar estadounidense	US Dollar	USD	840	2
115	VIRGIN ISLANDS (U.S.)	Dólar estadounidense	US Dollar	USD	840	2
116	UNITED STATES OF AMERICA (THE)	Dólar estadounidense (día siguiente)	US Dollar (Next day)	USN	997	2
117	UNITED STATES OF AMERICA (THE)	Dólar estadounidense (el mismo día)	US Dollar (Same day)	USN	997	2
118	JAMAICA	Dólar jamaicano	Jamaican Dollar	JMD	388	2
119	LIBERIA	Dólar liberiano	Liberian Dollar	LRD	430	2
120	VIET NAM	Dong	Dong	VND	704	0
121	ARMENIA	Dram Armenio	Armenian Dram	AMD	051	2
122	ÅLAND ISLANDS	Euro	Euro	EUR	978	2
123	ANDORRA	Euro	Euro	EUR	978	2
124	AUSTRIA	Euro	Euro	EUR	978	2
125	BELGIUM	Euro	Euro	EUR	978	2
126	CYPRUS	Euro	Euro	EUR	978	2
127	ESTONIA	Euro	Euro	EUR	978	2
128	EUROPEAN UNION	Euro	Euro	EUR	978	2
129	FINLAND	Euro	Euro	EUR	978	2
130	FRANCE	Euro	Euro	EUR	978	2
131	FRENCH GUIANA	Euro	Euro	EUR	978	2
132	FRENCH SOUTHERN TERRITORIES (THE)	Euro	Euro	EUR	978	2
133	GERMANY	Euro	Euro	EUR	978	2
134	GREECE	Euro	Euro	EUR	978	2
135	GUADELOUPE	Euro	Euro	EUR	978	2
136	HOLY SEE (THE)	Euro	Euro	EUR	978	2
137	IRELAND	Euro	Euro	EUR	978	2
138	ITALY	Euro	Euro	EUR	978	2
139	LATVIA	Euro	Euro	EUR	978	2
140	LITHUANIA	Euro	Euro	EUR	978	2
141	LUXEMBOURG	Euro	Euro	EUR	978	2
142	MALTA	Euro	Euro	EUR	978	2
143	MARTINIQUE	Euro	Euro	EUR	978	2
144	MAYOTTE	Euro	Euro	EUR	978	2
145	MONACO	Euro	Euro	EUR	978	2
146	MONTENEGRO	Euro	Euro	EUR	978	2
147	NETHERLANDS (THE)	Euro	Euro	EUR	978	2
148	PORTUGAL	Euro	Euro	EUR	978	2
149	RÉUNION	Euro	Euro	EUR	978	2
150	SAINT BARTHÉLEMY	Euro	Euro	EUR	978	2
151	SAINT MARTIN (FRENCH PART)	Euro	Euro	EUR	978	2
152	SAINT PIERRE AND MIQUELON	Euro	Euro	EUR	978	2
153	SAN MARINO	Euro	Euro	EUR	978	2
154	SLOVAKIA	Euro	Euro	EUR	978	2
155	SLOVENIA	Euro	Euro	EUR	978	2
156	SPAIN	Euro	Euro	EUR	978	2
157	HUNGARY	Forint	Forint	HUF	348	2
158	FRENCH POLYNESIA	Franco CFP	CFP Franc	XPF	953	0
159	NEW CALEDONIA	Franco CFP	CFP Franc	XPF	953	0
160	WALLIS AND FUTUNA	Franco CFP	CFP Franc	XPF	953	0
161	CONGO (THE DEMOCRATIC REPUBLIC OF THE)	Franco Congolés	Congolese Franc	CDF	976	2
162	BURUNDI	Franco de Burundi	Burundi Franc	BIF	108	0
163	DJIBOUTI	Franco de Djibouti	Djibouti Franc	DJF	262	0
164	RWANDA	Franco ruanda	Rwanda Franc	RWF	646	0
165	LIECHTENSTEIN	Franco suizo	Swiss Franc	CHF	756	2
166	SWITZERLAND	Franco suizo	Swiss Franc	CHF	756	2
167	HAITI	Gourde	Gourde	HTG	332	2
168	PARAGUAY	Guaraní	Guarani	PYG	600	0
169	GUINEA	Guinea Franc	Guinea Franc	GNF	324	0
170	UKRAINE	Hryvnia	Hryvnia	UAH	980	2
171	INTERNATIONAL MONETARY FUND (IMF) 	SDR (Special Drawing Right)	SDR (Special Drawing Right)	XDR	960	N.A.
172	PAPUA NEW GUINEA	Kina	Kina	PGK	598	2
173	LAO PEOPLE’S DEMOCRATIC REPUBLIC (THE)	Kip	Kip	LAK	418	2
174	CROATIA	Kuna	Kuna	HRK	191	2
175		Kwacha zambiano	Kwacha zambiano	ZMK		
176	ANGOLA	Kwanza	Kwanza	AOA	973	2
177	MYANMAR	Kyat	Kyat	MMK	104	2
178	GEORGIA	Lari	Lari	GEL	981	2
179	ALBANIA	Lek	Lek	ALL	008	2
180	HONDURAS	Lempira	Lempira	HNL	340	2
181	SIERRA LEONE	Leone	Leone	SLL	694	2
182	MOLDOVA (THE REPUBLIC OF)	Leu moldavo	Moldovan Leu	MDL	498	2
183	ROMANIA	Leu rumano	Romanian Leu	RON	946	2
184	BULGARIA	Lev búlgaro	Bulgarian Lev	BGN	975	2
185	GIBRALTAR	Libra de Gilbraltar	Gibraltar Pound	GIP	292	2
186	FALKLAND ISLANDS (THE) [MALVINAS]	Libra de las Islas Malvinas	Falkland Islands Pound	FKP	238	2
187	SAINT HELENA, ASCENSION AND TRISTAN DA CUNHA	Libra de Santa Helena	Saint Helena Pound	SHP	654	2
188	EGYPT	Libra egipcia	Egyptian Pound	EGP	818	2
189	GUERNSEY	Libra esterlina	Pound Sterling	GBP	826	2
190	ISLE OF MAN	Libra esterlina	Pound Sterling	GBP	826	2
191	JERSEY	Libra esterlina	Pound Sterling	GBP	826	2
192	UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND (THE)	Libra esterlina	Pound Sterling	GBP	826	2
193	LEBANON	Libra libanesa	Lebanese Pound	LBP	422	2
194	SYRIAN ARAB REPUBLIC	Libra siria	Syrian Pound	SYP	760	2
195	SUDAN (THE)	Libra sudanesa	Sudanese Pound	SDG	938	2
196	SOUTH SUDAN	Libra sudanesa	South Sudanese Pound	SSP	728	2
197	SWAZILAND	Lilangeni	Lilangeni	SZL	748	2
198	TURKEY	Lira turca	Lira turca	TRY	949	2
199	LESOTHO	Loti	Loti	LSL	426	2
200		Litas de Lituana	Litas de Lituana	LTL		
201		Lats letón	Lats letón	LvL		
202	MALAWI	Malawi Kwacha	Malawi Kwacha	MWK	454	2
203	TURKMENISTAN	Manat	Turkmenistan New Manat	TMT	934	2
204	AZERBAIJAN	Manat Azerbaiyano	Azerbaijanian Manat	AZN	944	2
205	MOZAMBIQUE	Metical	Mozambique Metical	MZN	943	2
206	BOLIVIA (PLURINATIONAL STATE OF)	Mvdol	Mvdol	BOV	984	2
207	NIGERIA	Naira	Naira	NGN	566	2
208	ERITREA	Nakfa	Nakfa	ERN	232	2
209	CURAÇAO	Netherlands Antillean Guilder	Netherlands Antillean Guilder	ANG	532	2
210	SINT MAARTEN (DUTCH PART)	Netherlands Antillean Guilder	Netherlands Antillean Guilder	ANG	532	2
211	BHUTAN	Ngultrum	Ngultrum	BTN	064	2
212	TAIWAN (PROVINCE OF CHINA)	Nuevo dólar de Taiwán	New Taiwan Dollar	TWD	901	2
213	ISRAEL	Nuevo shekel israelí	New Israeli Sheqel	ILS	376	2
214	PERU	Nuevo Sol	Sol	PEN	604	2
215	MAURITANIA	Ouguiya	Ouguiya	MRO	478	2
216	MACAO	Pataca	Pataca	MOP	446	2
217	ARGENTINA	Peso argentino	Argentine Peso	ARS	032	2
218	CHILE	Peso chileno	Chilean Peso	CLP	152	0
219	COLOMBIA	Peso colombiano	Colombian Peso	COP	170	2
220	CUBA	Peso Convertible	Peso Convertible	CUC	931	2
221	CUBA	Peso cubano	Cuban Peso	CUP	192	2
222	DOMINICAN REPUBLIC (THE)	Peso Dominicano	Dominican Peso	DOP	214	2
223	MEXICO	Peso Mexicano	Mexican Peso	MXN	484	2
224	URUGUAY	Peso Uruguayo	Peso Uruguayo	UYU	858	2
225	PHILIPPINES (THE)	Philippine Peso	Philippine Peso	PHP	608	2
226	BOTSWANA	Pula	Pula	BWP	072	2
227	GUATEMALA	Quetzal	Quetzal	GTQ	320	2
228	LESOTHO	Rand	Rand	ZAR	710	2
229	NAMIBIA	Rand	Rand	ZAR	710	2
230	SOUTH AFRICA	Rand	Rand	ZAR	710	2
231	BRAZIL	Real brasileño	Brazilian Real	BRL	986	2
232	QATAR	Rial de Qatar	Qatari Rial	QAR	634	2
233	IRAN (ISLAMIC REPUBLIC OF)	Rial iraní	Iranian Rial	IRR	364	2
234	OMAN	Rial Omani	Rial Omani	OMR	512	3
235	YEMEN	Rial yenemí	Yemeni Rial	YER	886	2
236	CAMBODIA	Riel	Riel	KHR	116	2
237	MALAYSIA	Ringgit malayo	Malaysian Ringgit	MYR	458	2
238	SAUDI ARABIA	Riyal saudita	Saudi Riyal	SAR	682	2
239	RUSSIAN FEDERATION (THE)	Rublo ruso	Russian Ruble	RUB	643	2
240	MALDIVES	Rufiyaa	Rufiyaa	MVR	462	2
241	INDONESIA	Rupia	Rupiah	IDR	360	2
242	MAURITIUS	Rupia de Mauricio	Mauritius Rupee	MUR	480	2
243	PAKISTAN	Rupia de Pakistán	Pakistan Rupee	PKR	586	2
244	SEYCHELLES	Rupia de Seychelles	Seychelles Rupee	SCR	690	2
245	SRI LANKA	Rupia de Sri Lanka	Sri Lanka Rupee	LKR	144	2
246	BHUTAN	Rupia india	Indian Rupee	INR	356	2
247	INDIA	Rupia india	Indian Rupee	INR	356	2
248	NEPAL	Rupia nepalí	Nepalese Rupee	NPR	524	2
249	KYRGYZSTAN	Som	Som	KGS	417	2
250	TAJIKISTAN	Somoni	Somoni	TJS	972	2
251	UZBEKISTAN	Suma de Uzbekistán	Uzbekistan Sum	UZS	860	2
252	BANGLADESH	Taka	Taka	BDT	050	2
253	SAMOA	Tala	Tala	WST	882	2
254	KAZAKHSTAN	Tenge	Tenge	KZT	398	2
255	MONGOLIA	Tugrik	Tugrik	MNT	496	2
256	MEXICO	Unidad de Inversión Mexicana (UDI)	Mexican Unidad de Inversion (UDI)	MXV	979	2
257	COLOMBIA	Unidad de Valor Real	Unidad de Valor Real	COU	970	2
258	CHILE	Unidades de Fomento	Unidad de Fomento	CLF	990	4
259	URUGUAY	Uruguay Peso en Unidades Indexadas	Uruguay Peso en Unidades Indexadas (URUIURUI)	UYI	940	0
260	VANUATU	Vatu	Vatu	VUV	548	0
261	KOREA (THE REPUBLIC OF)	Won	Won	KRW	410	0
262	KOREA (THE DEMOCRATIC PEOPLE’S REPUBLIC OF)	Won de Corea del Norte	North Korean Won	KPW	408	2
263	JAPAN	Yen	Yen	JPY	392	0
264	CHINA	Yuan Renminbi	Yuan Renminbi	CNY	156	2
265	POLAND	Zloty	Zloty	PLN	985	2
\.


--
-- Data for Name: datapnt; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.datapnt (id, contractingprocess_id, fiscalyear, reportingperiodstartdate, reportingperiodenddate, dataresponsibleunit, valitationdate, updatedate, notes, data_pnt) FROM stdin;
\.


--
-- Data for Name: documentformat; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.documentformat (id, category, name, template, reference) FROM stdin;
1	application	1d-interleaved-parityfec	application/1d-interleaved-parityfec	[RFC6015]
2	application	3gpdash-qoe-report+xml	application/3gpdash-qoe-report+xml	[_3GPP][Ozgur_Oyman]
3	application	3gpp-ims+xml	application/3gpp-ims+xml	[John_M_Meredith]
4	application	A2L	application/A2L	[ASAM][Thomas_Thomsen]
5	application	activemessage	application/activemessage	[Ehud_Shapiro]
6	application	activemessage	application/activemessage	[Ehud_Shapiro]
7	application	alto-costmap+json	application/alto-costmap+json	[RFC7285]
8	application	alto-costmapfilter+json	application/alto-costmapfilter+json	[RFC7285]
9	application	alto-directory+json	application/alto-directory+json	[RFC7285]
10	application	alto-endpointprop+json	application/alto-endpointprop+json	[RFC7285]
11	application	alto-endpointpropparams+json	application/alto-endpointpropparams+json	[RFC7285]
12	application	alto-endpointcost+json	application/alto-endpointcost+json	[RFC7285]
13	application	alto-endpointcostparams+json	application/alto-endpointcostparams+json	[RFC7285]
14	application	alto-error+json	application/alto-error+json	[RFC7285]
15	application	alto-networkmapfilter+json	application/alto-networkmapfilter+json	[RFC7285]
16	application	alto-networkmap+json	application/alto-networkmap+json	[RFC7285]
17	application	AML	application/AML	[ASAM][Thomas_Thomsen]
18	application	andrew-inset	application/andrew-inset	[Nathaniel_Borenstein]
19	application	applefile	application/applefile	[Patrik_Faltstrom]
20	application	ATF	application/ATF	[ASAM][Thomas_Thomsen]
21	application	ATFX	application/ATFX	[ASAM][Thomas_Thomsen]
22	application	atom+xml	application/atom+xml	[RFC4287][RFC5023]
23	application	atomcat+xml	application/atomcat+xml	[RFC5023]
24	application	atomdeleted+xml	application/atomdeleted+xml	[RFC6721]
25	application	atomicmail	application/atomicmail	[Nathaniel_Borenstein]
26	application	atomsvc+xml	application/atomsvc+xml	[RFC5023]
27	application	ATXML	application/ATXML	[ASAM][Thomas_Thomsen]
28	application	auth-policy+xml	application/auth-policy+xml	[RFC4745]
29	application	bacnet-xdd+zip	application/bacnet-xdd+zip	[ASHRAE][Dave_Robin]
30	application	batch-SMTP	application/batch-SMTP	[RFC2442]
31	application	beep+xml	application/beep+xml	[RFC3080]
32	application	calendar+json	application/calendar+json	[RFC7265]
33	application	calendar+xml	application/calendar+xml	[RFC6321]
34	application	call-completion	application/call-completion	[RFC6910]
35	application	CALS-1840	application/CALS-1840	[RFC1895]
36	application	cbor	application/cbor	[RFC7049]
37	application	ccmp+xml	application/ccmp+xml	[RFC6503]
38	application	ccxml+xml	application/ccxml+xml	[RFC4267]
39	application	CDFX+XML	application/CDFX+XML	[ASAM][Thomas_Thomsen]
40	application	cdmi-capability	application/cdmi-capability	[RFC6208]
41	application	cdmi-container	application/cdmi-container	[RFC6208]
42	application	cdmi-domain	application/cdmi-domain	[RFC6208]
43	application	cdmi-object	application/cdmi-object	[RFC6208]
44	application	cdmi-queue	application/cdmi-queue	[RFC6208]
45	application	cdni	application/cdni	[RFC7736]
46	application	CEA	application/CEA	[ASAM][Thomas_Thomsen]
47	application	cea-2018+xml	application/cea-2018+xml	[Gottfried_Zimmermann]
48	application	cellml+xml	application/cellml+xml	[RFC4708]
49	application	cfw	application/cfw	[RFC6230]
50	application	clue_info+xml	application/clue_info+xml	[RFC-ietf-clue-data-model-schema-17]
51	application	cms	application/cms	[RFC7193]
52	application	cnrp+xml	application/cnrp+xml	[RFC3367]
53	application	coap-group+json	application/coap-group+json	[RFC7390]
54	application	commonground	application/commonground	[David_Glazer]
55	application	conference-info+xml	application/conference-info+xml	[RFC4575]
56	application	cpl+xml	application/cpl+xml	[RFC3880]
57	application	csrattrs	application/csrattrs	[RFC7030]
58	application	csta+xml	application/csta+xml	[Ecma_International_Helpdesk]
59	application	CSTAdata+xml	application/CSTAdata+xml	[Ecma_International_Helpdesk]
60	application	csvm+json	application/csvm+json	[W3C][Ivan_Herman]
61	application	cybercash	application/cybercash	[Donald_E._Eastlake_3rd]
62	application	dash+xml	application/dash+xml	[Thomas_Stockhammer][ISO-IEC_JTC1]
63	application	dashdelta	application/dashdelta	[David_Furbeck]
64	application	davmount+xml	application/davmount+xml	[RFC4709]
65	application	dca-rft	application/dca-rft	[Larry_Campbell]
66	application	DCD	application/DCD	[ASAM][Thomas_Thomsen]
67	application	dec-dx	application/dec-dx	[Larry_Campbell]
68	application	dialog-info+xml	application/dialog-info+xml	[RFC4235]
69	application	dicom	application/dicom	[RFC3240]
70	application	dicom+json	application/dicom+json	[DICOM_Standards_Committee][David_Clunie][James_F_Philbin]
71	application	dicom+xml	application/dicom+xml	[DICOM_Standards_Committee][David_Clunie][James_F_Philbin]
72	application	DII	application/DII	[ASAM][Thomas_Thomsen]
73	application	DIT	application/DIT	[ASAM][Thomas_Thomsen]
74	application	dns	application/dns	[RFC4027]
75	application	dskpp+xml	application/dskpp+xml	[RFC6063]
76	application	dssc+der	application/dssc+der	[RFC5698]
77	application	dssc+xml	application/dssc+xml	[RFC5698]
78	application	dvcs	application/dvcs	[RFC3029]
79	application	ecmascript	application/ecmascript	[RFC4329]
80	application	EDI-consent	application/EDI-consent	[RFC1767]
81	application	EDIFACT	application/EDIFACT	[RFC1767]
82	application	EDI-X12	application/EDI-X12	[RFC1767]
83	application	efi	application/efi	[UEFI_Forum][Samer_El-Haj-Mahmoud]
84	application	EmergencyCallData.Comment+xml	application/EmergencyCallData.Comment+xml	[RFC7852]
85	application	EmergencyCallData.DeviceInfo+xml	application/EmergencyCallData.DeviceInfo+xml	[RFC7852]
86	application	EmergencyCallData.ProviderInfo+xml	application/EmergencyCallData.ProviderInfo+xml	[RFC7852]
87	application	EmergencyCallData.ServiceInfo+xml	application/EmergencyCallData.ServiceInfo+xml	[RFC7852]
88	application	EmergencyCallData.SubscriberInfo+xml	application/EmergencyCallData.SubscriberInfo+xml	[RFC7852]
89	application	emma+xml		[W3C][http://www.w3.org/TR/2007/CR-emma-20071211/#media-type-registration][ISO-IEC JTC1]
90	application	emotionml+xml	application/emotionml+xml	[W3C][Kazuyuki_Ashimura]
91	application	encaprtp	application/encaprtp	[RFC6849]
92	application	epp+xml	application/epp+xml	[RFC5730]
93	application	epub+zip	application/epub+zip	[International_Digital_Publishing_Forum][William_McCoy]
94	application	eshop	application/eshop	[Steve_Katz]
95	application	example	application/example	[RFC4735]
96	application	exi		[W3C][http://www.w3.org/TR/2009/CR-exi-20091208/#mediaTypeRegistration]
97	application	fastinfoset	application/fastinfoset	[ITU-T_ASN.1_Rapporteur]
98	application	fastsoap	application/fastsoap	[ITU-T_ASN.1_Rapporteur]
99	application	fdt+xml	application/fdt+xml	[RFC6726]
100	application	fits	application/fits	[RFC4047]
101	application	font-sfnt	application/font-sfnt	[Levantovsky][ISO-IEC JTC1]
102	application	font-tdpfr	application/font-tdpfr	[RFC3073]
103	application	font-woff	application/font-woff	[W3C]
104	application	framework-attributes+xml	application/framework-attributes+xml	[RFC6230]
105	application	geo+json	application/geo+json	[RFC7946]
106	application	gzip	application/gzip	[RFC6713]
107	application	H224	application/H224	[RFC4573]
108	application	held+xml	application/held+xml	[RFC5985]
109	application	http	application/http	[RFC7230]
110	application	hyperstudio	application/hyperstudio	[Michael_Domino]
111	application	ibe-key-request+xml	application/ibe-key-request+xml	[RFC5408]
112	application	ibe-pkg-reply+xml	application/ibe-pkg-reply+xml	[RFC5408]
113	application	ibe-pp-data	application/ibe-pp-data	[RFC5408]
114	application	iges	application/iges	[Curtis_Parks]
115	application	im-iscomposing+xml	application/im-iscomposing+xml	[RFC3994]
116	application	index	application/index	[RFC2652]
117	application	index.cmd	application/index.cmd	[RFC2652]
118	application	index.obj	application/index-obj	[RFC2652]
119	application	index.response	application/index.response	[RFC2652]
120	application	index.vnd	application/index.vnd	[RFC2652]
121	application	inkml+xml	application/inkml+xml	[Kazuyuki_Ashimura]
122	application	iotp	application/IOTP	[RFC2935]
123	application	ipfix	application/ipfix	[RFC5655]
124	application	ipp	application/ipp	[RFC-sweet-rfc2910bis-09]
125	application	isup	application/ISUP	[RFC3204]
126	application	its+xml	application/its+xml	[W3C][ITS-IG-W3C]
127	application	javascript	application/javascript	[RFC4329]
128	application	jose	application/jose	[RFC7515]
129	application	jose+json	application/jose+json	[RFC7515]
130	application	jrd+json	application/jrd+json	[RFC7033]
131	application	json	application/json	[RFC7159]
132	application	json-patch+json	application/json-patch+json	[RFC6902]
133	application	json-seq	application/json-seq	[RFC7464]
134	application	jwk+json	application/jwk+json	[RFC7517]
135	application	jwk-set+json	application/jwk-set+json	[RFC7517]
136	application	jwt	application/jwt	[RFC7519]
137	application	kpml-request+xml	application/kpml-request+xml	[RFC4730]
138	application	kpml-response+xml	application/kpml-response+xml	[RFC4730]
139	application	ld+json	application/ld+json	[W3C][Ivan_Herman]
140	application	lgr+xml	application/lgr+xml	[RFC7940]
141	application	link-format	application/link-format	[RFC6690]
142	application	load-control+xml	application/load-control+xml	[RFC7200]
143	application	lost+xml	application/lost+xml	[RFC5222]
144	application	lostsync+xml	application/lostsync+xml	[RFC6739]
145	application	LXF	application/LXF	[ASAM][Thomas_Thomsen]
146	application	mac-binhex40	application/mac-binhex40	[Patrik_Faltstrom]
147	application	macwriteii	application/macwriteii	[Paul_Lindner]
148	application	mads+xml	application/mads+xml	[RFC6207]
149	application	marc	application/marc	[RFC2220]
150	application	marcxml+xml	application/marcxml+xml	[RFC6207]
151	application	mathematica	application/mathematica	[Wolfram]
152	application	mathml-content+xml		[W3C][http://www.w3.org/TR/MathML3/appendixb.html]
153	application	mathml-presentation+xml		[W3C][http://www.w3.org/TR/MathML3/appendixb.html]
154	application	mathml+xml		[W3C][http://www.w3.org/TR/MathML3/appendixb.html]
155	application	mbms-associated-procedure-description+xml	application/mbms-associated-procedure-description+xml	[_3GPP]
156	application	mbms-deregister+xml	application/mbms-deregister+xml	[_3GPP]
157	application	mbms-envelope+xml	application/mbms-envelope+xml	[_3GPP]
158	application	mbms-msk-response+xml	application/mbms-msk-response+xml	[_3GPP]
159	application	mbms-msk+xml	application/mbms-msk+xml	[_3GPP]
160	application	mbms-protection-description+xml	application/mbms-protection-description+xml	[_3GPP]
161	application	mbms-reception-report+xml	application/mbms-reception-report+xml	[_3GPP]
162	application	mbms-register-response+xml	application/mbms-register-response+xml	[_3GPP]
163	application	mbms-register+xml	application/mbms-register+xml	[_3GPP]
164	application	mbms-schedule+xml	application/mbms-schedule+xml	[_3GPP][Eric_Turcotte]
165	application	mbms-user-service-description+xml	application/mbms-user-service-description+xml	[_3GPP]
166	application	mbox	application/mbox	[RFC4155]
167	application	media_control+xml	application/media_control+xml	[RFC5168]
168	application	media-policy-dataset+xml	application/media-policy-dataset+xml	[RFC6796]
169	application	mediaservercontrol+xml	application/mediaservercontrol+xml	[RFC5022]
170	application	merge-patch+json	application/merge-patch+json	[RFC7396]
171	application	metalink4+xml	application/metalink4+xml	[RFC5854]
172	application	mets+xml	application/mets+xml	[RFC6207]
173	application	MF4	application/MF4	[ASAM][Thomas_Thomsen]
174	application	mikey	application/mikey	[RFC3830]
175	application	mods+xml	application/mods+xml	[RFC6207]
176	application	moss-keys	application/moss-keys	[RFC1848]
177	application	moss-signature	application/moss-signature	[RFC1848]
178	application	mosskey-data	application/mosskey-data	[RFC1848]
179	application	mosskey-request	application/mosskey-request	[RFC1848]
180	application	mp21	application/mp21	[RFC6381][David_Singer]
181	application	mp4	application/mp4	[RFC4337][RFC6381]
182	application	mpeg4-generic	application/mpeg4-generic	[RFC3640]
183	application	mpeg4-iod	application/mpeg4-iod	[RFC4337]
184	application	mpeg4-iod-xmt	application/mpeg4-iod-xmt	[RFC4337]
185	application	mrb-consumer+xml	application/mrb-consumer+xml	[RFC6917]
186	application	mrb-publish+xml	application/mrb-publish+xml	[RFC6917]
187	application	msc-ivr+xml	application/msc-ivr+xml	[RFC6231]
188	application	msc-mixer+xml	application/msc-mixer+xml	[RFC6505]
189	application	msword	application/msword	[Paul_Lindner]
190	application	mxf	application/mxf	[RFC4539]
191	application	nasdata	application/nasdata	[RFC4707]
192	application	news-checkgroups	application/news-checkgroups	[RFC5537]
193	application	news-groupinfo	application/news-groupinfo	[RFC5537]
194	application	news-transmission	application/news-transmission	[RFC5537]
195	application	nlsml+xml	application/nlsml+xml	[RFC6787]
196	application	nss	application/nss	[Michael_Hammer]
197	application	ocsp-request	application/ocsp-request	[RFC6960]
198	application	ocsp-response	application/ocsp-response	[RFC6960]
199	application	octet-stream	application/octet-stream	[RFC2045][RFC2046]
200	application	oda	application/ODA	[RFC2045][RFC2046]
201	application	ODX	application/ODX	[ASAM][Thomas_Thomsen]
202	application	oebps-package+xml	application/oebps-package+xml	[RFC4839]
203	application	ogg	application/ogg	[RFC5334][RFC7845]
204	application	oxps	application/oxps	[Ecma_International_Helpdesk]
205	application	p2p-overlay+xml	application/p2p-overlay+xml	[RFC6940]
206	application	parityfec		[RFC5109]
207	application	patch-ops-error+xml	application/patch-ops-error+xml	[RFC5261]
208	application	pdf	application/pdf	[RFC3778]
209	application	PDX	application/PDX	[ASAM][Thomas_Thomsen]
210	application	pgp-encrypted	application/pgp-encrypted	[RFC3156]
211	application	pgp-keys		[RFC3156]
212	application	pgp-signature	application/pgp-signature	[RFC3156]
213	application	pidf-diff+xml	application/pidf-diff+xml	[RFC5262]
214	application	pidf+xml	application/pidf+xml	[RFC3863]
215	application	pkcs10	application/pkcs10	[RFC5967]
216	application	pkcs7-mime	application/pkcs7-mime	[RFC5751][RFC7114]
217	application	pkcs7-signature	application/pkcs7-signature	[RFC5751]
218	application	pkcs8	application/pkcs8	[RFC5958]
219	application	pkcs12	application/pkcs12	[IETF]
220	application	pkix-attr-cert	application/pkix-attr-cert	[RFC5877]
221	application	pkix-cert	application/pkix-cert	[RFC2585]
222	application	pkix-crl	application/pkix-crl	[RFC2585]
223	application	pkix-pkipath	application/pkix-pkipath	[RFC6066]
224	application	pkixcmp	application/pkixcmp	[RFC2510]
225	application	pls+xml	application/pls+xml	[RFC4267]
226	application	poc-settings+xml	application/poc-settings+xml	[RFC4354]
227	application	postscript	application/postscript	[RFC2045][RFC2046]
228	application	ppsp-tracker+json	application/ppsp-tracker+json	[RFC7846]
229	application	problem+json	application/problem+json	[RFC7807]
230	application	problem+xml	application/problem+xml	[RFC7807]
231	application	provenance+xml	application/provenance+xml	[W3C][Ivan_Herman]
232	application	prs.alvestrand.titrax-sheet	application/prs.alvestrand.titrax-sheet	[Harald_T._Alvestrand]
233	application	prs.cww	application/prs.cww	[Khemchart_Rungchavalnont]
234	application	prs.hpub+zip	application/prs.hpub+zip	[Giulio_Zambon]
235	application	prs.nprend	application/prs.nprend	[Jay_Doggett]
236	application	prs.plucker	application/prs.plucker	[Bill_Janssen]
237	application	prs.rdf-xml-crypt	application/prs.rdf-xml-crypt	[Toby_Inkster]
238	application	prs.xsf+xml	application/prs.xsf+xml	[Maik_Stührenberg]
239	application	pskc+xml	application/pskc+xml	[RFC6030]
240	application	rdf+xml	application/rdf+xml	[RFC3870]
241	application	qsig	application/QSIG	[RFC3204]
242	application	raptorfec	application/raptorfec	[RFC6682]
243	application	rdap+json	application/rdap+json	[RFC7483]
244	application	reginfo+xml	application/reginfo+xml	[RFC3680]
245	application	relax-ng-compact-syntax	application/relax-ng-compact-syntax	[http://www.jtc1sc34.org/repository/0661.pdf]
246	application	remote-printing	application/remote-printing	[RFC1486][Marshall_Rose]
247	application	reputon+json	application/reputon+json	[RFC7071]
248	application	resource-lists-diff+xml	application/resource-lists-diff+xml	[RFC5362]
249	application	resource-lists+xml	application/resource-lists+xml	[RFC4826]
250	application	rfc+xml	application/rfc+xml	[RFC-iab-xml2rfc-04]
251	application	riscos	application/riscos	[Nick_Smith]
252	application	rlmi+xml	application/rlmi+xml	[RFC4662]
253	application	rls-services+xml	application/rls-services+xml	[RFC4826]
254	application	rpki-ghostbusters	application/rpki-ghostbusters	[RFC6493]
255	application	rpki-manifest	application/rpki-manifest	[RFC6481]
256	application	rpki-roa	application/rpki-roa	[RFC6481]
257	application	rpki-updown	application/rpki-updown	[RFC6492]
258	application	rtf	application/rtf	[Paul_Lindner]
259	application	rtploopback	application/rtploopback	[RFC6849]
260	application	rtx	application/rtx	[RFC4588]
261	application	samlassertion+xml	application/samlassertion+xml	[OASIS_Security_Services_Technical_Committee_SSTC]
262	application	samlmetadata+xml	application/samlmetadata+xml	[OASIS_Security_Services_Technical_Committee_SSTC]
263	application	sbml+xml	application/sbml+xml	[RFC3823]
264	application	scaip+xml	application/scaip+xml	[SIS][Oskar_Jonsson]
265	application	scim+json	application/scim+json	[RFC7644]
266	application	scvp-cv-request	application/scvp-cv-request	[RFC5055]
267	application	scvp-cv-response	application/scvp-cv-response	[RFC5055]
268	application	scvp-vp-request	application/scvp-vp-request	[RFC5055]
269	application	scvp-vp-response	application/scvp-vp-response	[RFC5055]
270	application	sdp	application/sdp	[RFC4566]
271	application	sep-exi	application/sep-exi	[Robby_Simpson][ZigBee]
272	application	sep+xml	application/sep+xml	[Robby_Simpson][ZigBee]
273	application	session-info	application/session-info	[_3GPP][Frederic_Firmin]
274	application	set-payment	application/set-payment	[Brian_Korver]
275	application	set-payment-initiation	application/set-payment-initiation	[Brian_Korver]
276	application	set-registration	application/set-registration	[Brian_Korver]
277	application	set-registration-initiation	application/set-registration-initiation	[Brian_Korver]
278	application	sgml	application/SGML	[RFC1874]
279	application	sgml-open-catalog	application/sgml-open-catalog	[Paul_Grosso]
280	application	shf+xml	application/shf+xml	[RFC4194]
281	application	sieve	application/sieve	[RFC5228]
282	application	simple-filter+xml	application/simple-filter+xml	[RFC4661]
283	application	simple-message-summary	application/simple-message-summary	[RFC3842]
284	application	simpleSymbolContainer	application/simpleSymbolContainer	[_3GPP]
285	application	slate	application/slate	[Terry_Crowley]
286	application	smil - OBSOLETED in favor of application/smil+xml	application/smil	[RFC4536]
287	application	smil+xml	application/smil+xml	[RFC4536]
288	application	smpte336m	application/smpte336m	[RFC6597]
289	application	soap+fastinfoset	application/soap+fastinfoset	[ITU-T_ASN.1_Rapporteur]
290	application	soap+xml	application/soap+xml	[RFC3902]
291	application	sparql-query		[W3C][http://www.w3.org/TR/2007/CR-rdf-sparql-query-20070614/#mediaType]
292	application	sparql-results+xml		[W3C][http://www.w3.org/TR/2007/CR-rdf-sparql-XMLres-20070925/#mime]
293	application	spirits-event+xml	application/spirits-event+xml	[RFC3910]
294	application	sql	application/sql	[RFC6922]
295	application	srgs	application/srgs	[RFC4267]
296	application	srgs+xml	application/srgs+xml	[RFC4267]
297	application	sru+xml	application/sru+xml	[RFC6207]
298	application	ssml+xml	application/ssml+xml	[RFC4267]
299	application	tamp-apex-update	application/tamp-apex-update	[RFC5934]
300	application	tamp-apex-update-confirm	application/tamp-apex-update-confirm	[RFC5934]
301	application	tamp-community-update	application/tamp-community-update	[RFC5934]
302	application	tamp-community-update-confirm	application/tamp-community-update-confirm	[RFC5934]
303	application	tamp-error	application/tamp-error	[RFC5934]
304	application	tamp-sequence-adjust	application/tamp-sequence-adjust	[RFC5934]
305	application	tamp-sequence-adjust-confirm	application/tamp-sequence-adjust-confirm	[RFC5934]
306	application	tamp-status-query	application/tamp-status-query	[RFC5934]
307	application	tamp-status-response	application/tamp-status-response	[RFC5934]
308	application	tamp-update	application/tamp-update	[RFC5934]
309	application	tamp-update-confirm	application/tamp-update-confirm	[RFC5934]
310	application	tei+xml	application/tei+xml	[RFC6129]
311	application	thraud+xml	application/thraud+xml	[RFC5941]
312	application	timestamp-query	application/timestamp-query	[RFC3161]
313	application	timestamp-reply	application/timestamp-reply	[RFC3161]
314	application	timestamped-data	application/timestamped-data	[RFC5955]
315	application	ttml+xml	application/ttml+xml	[W3C][W3C_Timed_Text_Working_Group]
316	application	tve-trigger	application/tve-trigger	[Linda_Welsh]
317	application	ulpfec	application/ulpfec	[RFC5109]
318	application	urc-grpsheet+xml	application/urc-grpsheet+xml	[Gottfried_Zimmermann][ISO-IEC JTC1]
319	application	urc-ressheet+xml	application/urc-ressheet+xml	[Gottfried_Zimmermann][ISO-IEC JTC1]
320	application	urc-targetdesc+xml	application/urc-targetdesc+xml	[Gottfried_Zimmermann][ISO-IEC JTC1]
321	application	urc-uisocketdesc+xml	application/urc-uisocketdesc+xml	[Gottfried_Zimmermann]
322	application	vcard+json	application/vcard+json	[RFC7095]
323	application	vcard+xml	application/vcard+xml	[RFC6351]
324	application	vemmi	application/vemmi	[RFC2122]
325	application	vnd.3gpp.access-transfer-events+xml	application/vnd.3gpp.access-transfer-events+xml	[Frederic_Firmin]
326	application	vnd.3gpp.bsf+xml	application/vnd.3gpp.bsf+xml	[John_M_Meredith]
327	application	vnd.3gpp.mid-call+xml	application/vnd.3gpp.mid-call+xml	[Frederic_Firmin]
328	application	vnd.3gpp.pic-bw-large	application/vnd.3gpp.pic-bw-large	[John_M_Meredith]
1162	application	wita	application/wita	[Larry_Campbell]
329	application	vnd.3gpp.pic-bw-small	application/vnd.3gpp.pic-bw-small	[John_M_Meredith]
330	application	vnd.3gpp.pic-bw-var	application/vnd.3gpp.pic-bw-var	[John_M_Meredith]
331	application	vnd.3gpp-prose-pc3ch+xml	application/vnd.3gpp-prose-pc3ch+xml	[Frederic_Firmin]
332	application	vnd.3gpp-prose+xml	application/vnd.3gpp-prose+xml	[Frederic_Firmin]
333	application	vnd.3gpp.sms	application/vnd.3gpp.sms	[John_M_Meredith]
334	application	vnd.3gpp.sms+xml	application/vnd.3gpp.sms+xml	[Frederic_Firmin]
335	application	vnd.3gpp.srvcc-ext+xml	application/vnd.3gpp.srvcc-ext+xml	[Frederic_Firmin]
336	application	vnd.3gpp.SRVCC-info+xml	application/vnd.3gpp.SRVCC-info+xml	[Frederic_Firmin]
337	application	vnd.3gpp.state-and-event-info+xml	application/vnd.3gpp.state-and-event-info+xml	[Frederic_Firmin]
338	application	vnd.3gpp.ussd+xml	application/vnd.3gpp.ussd+xml	[Frederic_Firmin]
339	application	vnd.3gpp2.bcmcsinfo+xml	application/vnd.3gpp2.bcmcsinfo+xml	[Andy_Dryden]
340	application	vnd.3gpp2.sms	application/vnd.3gpp2.sms	[AC_Mahendran]
341	application	vnd.3gpp2.tcap	application/vnd.3gpp2.tcap	[AC_Mahendran]
342	application	vnd.3lightssoftware.imagescal	application/vnd.3lightssoftware.imagescal	[Gus_Asadi]
343	application	vnd.3M.Post-it-Notes	application/vnd.3M.Post-it-Notes	[Michael_OBrien]
344	application	vnd.accpac.simply.aso	application/vnd.accpac.simply.aso	[Steve_Leow]
345	application	vnd.accpac.simply.imp	application/vnd.accpac.simply.imp	[Steve_Leow]
346	application	vnd.acucobol	application/vnd-acucobol	[Dovid_Lubin]
347	application	vnd.acucorp	application/vnd.acucorp	[Dovid_Lubin]
348	application	vnd.adobe.flash.movie	application/vnd.adobe.flash-movie	[Henrik_Andersson]
349	application	vnd.adobe.formscentral.fcdt	application/vnd.adobe.formscentral.fcdt	[Chris_Solc]
350	application	vnd.adobe.fxp	application/vnd.adobe.fxp	[Robert_Brambley][Steven_Heintz]
351	application	vnd.adobe.partial-upload	application/vnd.adobe.partial-upload	[Tapani_Otala]
352	application	vnd.adobe.xdp+xml	application/vnd.adobe.xdp+xml	[John_Brinkman]
353	application	vnd.adobe.xfdf	application/vnd.adobe.xfdf	[Roberto_Perelman]
354	application	vnd.aether.imp	application/vnd.aether.imp	[Jay_Moskowitz]
355	application	vnd.ah-barcode	application/vnd.ah-barcode	[Katsuhiko_Ichinose]
356	application	vnd.ahead.space	application/vnd.ahead.space	[Tor_Kristensen]
357	application	vnd.airzip.filesecure.azf	application/vnd.airzip.filesecure.azf	[Daniel_Mould][Gary_Clueit]
358	application	vnd.airzip.filesecure.azs	application/vnd.airzip.filesecure.azs	[Daniel_Mould][Gary_Clueit]
359	application	vnd.amazon.mobi8-ebook	application/vnd.amazon.mobi8-ebook	[Kim_Scarborough]
360	application	vnd.americandynamics.acc	application/vnd.americandynamics.acc	[Gary_Sands]
361	application	vnd.amiga.ami	application/vnd.amiga.ami	[Kevin_Blumberg]
362	application	vnd.amundsen.maze+xml	application/vnd.amundsen.maze+xml	[Mike_Amundsen]
363	application	vnd.anki	application/vnd.anki	[Kerrick_Staley]
364	application	vnd.anser-web-certificate-issue-initiation	application/vnd.anser-web-certificate-issue-initiation	[Hiroyoshi_Mori]
365	application	vnd.antix.game-component	application/vnd.antix.game-component	[Daniel_Shelton]
366	application	vnd.apache.thrift.binary	application/vnd.apache.thrift.binary	[Roger_Meier]
367	application	vnd.apache.thrift.compact	application/vnd.apache.thrift.compact	[Roger_Meier]
368	application	vnd.apache.thrift.json	application/vnd.apache.thrift.json	[Roger_Meier]
369	application	vnd.api+json	application/vnd.api+json	[Steve_Klabnik]
370	application	vnd.apple.mpegurl	application/vnd.apple.mpegurl	[David_Singer][Roger_Pantos]
371	application	vnd.apple.installer+xml	application/vnd.apple.installer+xml	[Peter_Bierman]
372	application	vnd.arastra.swi - OBSOLETED in favor of application/vnd.aristanetworks.swi	application/vnd.arastra.swi	[Bill_Fenner]
373	application	vnd.aristanetworks.swi	application/vnd.aristanetworks.swi	[Bill_Fenner]
374	application	vnd.artsquare	application/vnd.artsquare	[Christopher_Smith]
375	application	vnd.astraea-software.iota	application/vnd.astraea-software.iota	[Christopher_Snazell]
376	application	vnd.audiograph	application/vnd.audiograph	[Horia_Cristian_Slusanschi]
377	application	vnd.autopackage	application/vnd.autopackage	[Mike_Hearn]
378	application	vnd.avistar+xml	application/vnd.avistar+xml	[Vladimir_Vysotsky]
379	application	vnd.balsamiq.bmml+xml	application/vnd.balsamiq.bmml+xml	[Giacomo_Guilizzoni]
380	application	vnd.balsamiq.bmpr	application/vnd.balsamiq.bmpr	[Giacomo_Guilizzoni]
381	application	vnd.bekitzur-stech+json	application/vnd.bekitzur-stech+json	[Jegulsky]
382	application	vnd.biopax.rdf+xml	application/vnd.biopax.rdf+xml	[Pathway_Commons]
383	application	vnd.blueice.multipass	application/vnd.blueice.multipass	[Thomas_Holmstrom]
384	application	vnd.bluetooth.ep.oob	application/vnd.bluetooth.ep.oob	[Mike_Foley]
385	application	vnd.bluetooth.le.oob	application/vnd.bluetooth.le.oob	[Mark_Powell]
386	application	vnd.bmi	application/vnd.bmi	[Tadashi_Gotoh]
387	application	vnd.businessobjects	application/vnd.businessobjects	[Philippe_Imoucha]
388	application	vnd.cab-jscript	application/vnd.cab-jscript	[Joerg_Falkenberg]
389	application	vnd.canon-cpdl	application/vnd.canon-cpdl	[Shin_Muto]
390	application	vnd.canon-lips	application/vnd.canon-lips	[Shin_Muto]
391	application	vnd.cendio.thinlinc.clientconf	application/vnd.cendio.thinlinc.clientconf	[Peter_Astrand]
392	application	vnd.century-systems.tcp_stream	application/vnd.century-systems.tcp_stream	[Shuji_Fujii]
393	application	vnd.chemdraw+xml	application/vnd.chemdraw+xml	[Glenn_Howes]
394	application	vnd.chess-pgn	application/vnd.chess-pgn	[Kim_Scarborough]
395	application	vnd.chipnuts.karaoke-mmd	application/vnd.chipnuts.karaoke-mmd	[Chunyun_Xiong]
396	application	vnd.cinderella	application/vnd.cinderella	[Ulrich_Kortenkamp]
397	application	vnd.cirpack.isdn-ext	application/vnd.cirpack.isdn-ext	[Pascal_Mayeux]
398	application	vnd.citationstyles.style+xml	application/vnd.citationstyles.style+xml	[Rintze_M._Zelle]
399	application	vnd.claymore	application/vnd.claymore	[Ray_Simpson]
400	application	vnd.cloanto.rp9	application/vnd.cloanto.rp9	[Mike_Labatt]
401	application	vnd.clonk.c4group	application/vnd.clonk.c4group	[Guenther_Brammer]
402	application	vnd.cluetrust.cartomobile-config	application/vnd.cluetrust.cartomobile-config	[Gaige_Paulsen]
403	application	vnd.cluetrust.cartomobile-config-pkg	application/vnd.cluetrust.cartomobile-config-pkg	[Gaige_Paulsen]
404	application	vnd.coffeescript	application/vnd.coffeescript	[Devyn_Collier_Johnson]
405	application	vnd.collection.doc+json	application/vnd.collection.doc+json	[Irakli_Nadareishvili]
406	application	vnd.collection+json	application/vnd.collection+json	[Mike_Amundsen]
407	application	vnd.collection.next+json	application/vnd.collection.next+json	[Ioseb_Dzmanashvili]
408	application	vnd.comicbook+zip	application/vnd.comicbook+zip	[Kim_Scarborough]
409	application	vnd.commerce-battelle	application/vnd.commerce-battelle	[David_Applebaum]
410	application	vnd.commonspace	application/vnd.commonspace	[Ravinder_Chandhok]
411	application	vnd.coreos.ignition+json	application/vnd.coreos.ignition+json	[Alex_Crawford]
412	application	vnd.cosmocaller	application/vnd.cosmocaller	[Steve_Dellutri]
413	application	vnd.contact.cmsg	application/vnd.contact.cmsg	[Frank_Patz]
414	application	vnd.crick.clicker	application/vnd.crick.clicker	[Andrew_Burt]
415	application	vnd.crick.clicker.keyboard	application/vnd.crick.clicker.keyboard	[Andrew_Burt]
416	application	vnd.crick.clicker.palette	application/vnd.crick.clicker.palette	[Andrew_Burt]
417	application	vnd.crick.clicker.template	application/vnd.crick.clicker.template	[Andrew_Burt]
418	application	vnd.crick.clicker.wordbank	application/vnd.crick.clicker.wordbank	[Andrew_Burt]
419	application	vnd.criticaltools.wbs+xml	application/vnd.criticaltools.wbs+xml	[Jim_Spiller]
420	application	vnd.ctc-posml	application/vnd.ctc-posml	[Bayard_Kohlhepp]
421	application	vnd.ctct.ws+xml	application/vnd.ctct.ws+xml	[Jim_Ancona]
422	application	vnd.cups-pdf	application/vnd.cups-pdf	[Michael_Sweet]
423	application	vnd.cups-postscript	application/vnd.cups-postscript	[Michael_Sweet]
424	application	vnd.cups-ppd	application/vnd.cups-ppd	[Michael_Sweet]
425	application	vnd.cups-raster	application/vnd.cups-raster	[Michael_Sweet]
426	application	vnd.cups-raw	application/vnd.cups-raw	[Michael_Sweet]
427	application	vnd.curl	application/vnd-curl	[Robert_Byrnes]
428	application	vnd.cyan.dean.root+xml	application/vnd.cyan.dean.root+xml	[Matt_Kern]
429	application	vnd.cybank	application/vnd.cybank	[Nor_Helmee]
430	application	vnd.d2l.coursepackage1p0+zip	application/vnd.d2l.coursepackage1p0+zip	[Viktor_Haag]
431	application	vnd.dart	application/vnd-dart	[Anders_Sandholm]
432	application	vnd.data-vision.rdz	application/vnd.data-vision.rdz	[James_Fields]
433	application	vnd.debian.binary-package	application/vnd.debian.binary-package	[Charles_Plessy]
434	application	vnd.dece.data	application/vnd.dece.data	[Michael_A_Dolan]
435	application	vnd.dece.ttml+xml	application/vnd.dece.ttml+xml	[Michael_A_Dolan]
436	application	vnd.dece.unspecified	application/vnd.dece.unspecified	[Michael_A_Dolan]
437	application	vnd.dece.zip	application/vnd.dece-zip	[Michael_A_Dolan]
438	application	vnd.denovo.fcselayout-link	application/vnd.denovo.fcselayout-link	[Michael_Dixon]
439	application	vnd.desmume.movie	application/vnd.desmume-movie	[Henrik_Andersson]
440	application	vnd.dir-bi.plate-dl-nosuffix	application/vnd.dir-bi.plate-dl-nosuffix	[Yamanaka]
441	application	vnd.dm.delegation+xml	application/vnd.dm.delegation+xml	[Axel_Ferrazzini]
442	application	vnd.dna	application/vnd.dna	[Meredith_Searcy]
443	application	vnd.document+json	application/vnd.document+json	[Tom_Christie]
444	application	vnd.dolby.mobile.1	application/vnd.dolby.mobile.1	[Steve_Hattersley]
445	application	vnd.dolby.mobile.2	application/vnd.dolby.mobile.2	[Steve_Hattersley]
446	application	vnd.doremir.scorecloud-binary-document	application/vnd.doremir.scorecloud-binary-document	[Erik_Ronström]
447	application	vnd.dpgraph	application/vnd.dpgraph	[David_Parker]
448	application	vnd.dreamfactory	application/vnd.dreamfactory	[William_C._Appleton]
449	application	vnd.drive+json	application/vnd.drive+json	[Keith_Kester]
450	application	vnd.dtg.local	application/vnd.dtg.local	[Ali_Teffahi]
451	application	vnd.dtg.local.flash	application/vnd.dtg.local.flash	[Ali_Teffahi]
452	application	vnd.dtg.local.html	application/vnd.dtg.local-html	[Ali_Teffahi]
453	application	vnd.dvb.ait	application/vnd.dvb.ait	[Peter_Siebert][Michael_Lagally]
454	application	vnd.dvb.dvbj	application/vnd.dvb.dvbj	[Peter_Siebert][Michael_Lagally]
455	application	vnd.dvb.esgcontainer	application/vnd.dvb.esgcontainer	[Joerg_Heuer]
456	application	vnd.dvb.ipdcdftnotifaccess	application/vnd.dvb.ipdcdftnotifaccess	[Roy_Yue]
457	application	vnd.dvb.ipdcesgaccess	application/vnd.dvb.ipdcesgaccess	[Joerg_Heuer]
458	application	vnd.dvb.ipdcesgaccess2	application/vnd.dvb.ipdcesgaccess2	[Jerome_Marcon]
459	application	vnd.dvb.ipdcesgpdd	application/vnd.dvb.ipdcesgpdd	[Jerome_Marcon]
460	application	vnd.dvb.ipdcroaming	application/vnd.dvb.ipdcroaming	[Yiling_Xu]
461	application	vnd.dvb.iptv.alfec-base	application/vnd.dvb.iptv.alfec-base	[Jean-Baptiste_Henry]
462	application	vnd.dvb.iptv.alfec-enhancement	application/vnd.dvb.iptv.alfec-enhancement	[Jean-Baptiste_Henry]
463	application	vnd.dvb.notif-aggregate-root+xml	application/vnd.dvb.notif-aggregate-root+xml	[Roy_Yue]
464	application	vnd.dvb.notif-container+xml	application/vnd.dvb.notif-container+xml	[Roy_Yue]
465	application	vnd.dvb.notif-generic+xml	application/vnd.dvb.notif-generic+xml	[Roy_Yue]
466	application	vnd.dvb.notif-ia-msglist+xml	application/vnd.dvb.notif-ia-msglist+xml	[Roy_Yue]
467	application	vnd.dvb.notif-ia-registration-request+xml	application/vnd.dvb.notif-ia-registration-request+xml	[Roy_Yue]
468	application	vnd.dvb.notif-ia-registration-response+xml	application/vnd.dvb.notif-ia-registration-response+xml	[Roy_Yue]
469	application	vnd.dvb.notif-init+xml	application/vnd.dvb.notif-init+xml	[Roy_Yue]
470	application	vnd.dvb.pfr	application/vnd.dvb.pfr	[Peter_Siebert][Michael_Lagally]
471	application	vnd.dvb.service	application/vnd.dvb_service	[Peter_Siebert][Michael_Lagally]
472	application	vnd.dxr	application/vnd-dxr	[Michael_Duffy]
473	application	vnd.dynageo	application/vnd.dynageo	[Roland_Mechling]
474	application	vnd.dzr	application/vnd.dzr	[Carl_Anderson]
475	application	vnd.easykaraoke.cdgdownload	application/vnd.easykaraoke.cdgdownload	[Iain_Downs]
476	application	vnd.ecdis-update	application/vnd.ecdis-update	[Gert_Buettgenbach]
477	application	vnd.ecowin.chart	application/vnd.ecowin.chart	[Thomas_Olsson]
478	application	vnd.ecowin.filerequest	application/vnd.ecowin.filerequest	[Thomas_Olsson]
479	application	vnd.ecowin.fileupdate	application/vnd.ecowin.fileupdate	[Thomas_Olsson]
480	application	vnd.ecowin.series	application/vnd.ecowin.series	[Thomas_Olsson]
481	application	vnd.ecowin.seriesrequest	application/vnd.ecowin.seriesrequest	[Thomas_Olsson]
482	application	vnd.ecowin.seriesupdate	application/vnd.ecowin.seriesupdate	[Thomas_Olsson]
483	application	vnd.emclient.accessrequest+xml	application/vnd.emclient.accessrequest+xml	[Filip_Navara]
484	application	vnd.enliven	application/vnd.enliven	[Paul_Santinelli_Jr.]
485	application	vnd.enphase.envoy	application/vnd.enphase.envoy	[Chris_Eich]
486	application	vnd.eprints.data+xml	application/vnd.eprints.data+xml	[Tim_Brody]
487	application	vnd.epson.esf	application/vnd.epson.esf	[Shoji_Hoshina]
488	application	vnd.epson.msf	application/vnd.epson.msf	[Shoji_Hoshina]
489	application	vnd.epson.quickanime	application/vnd.epson.quickanime	[Yu_Gu]
490	application	vnd.epson.salt	application/vnd.epson.salt	[Yasuhito_Nagatomo]
491	application	vnd.epson.ssf	application/vnd.epson.ssf	[Shoji_Hoshina]
492	application	vnd.ericsson.quickcall	application/vnd.ericsson.quickcall	[Paul_Tidwell]
493	application	vnd.espass-espass+zip	application/vnd.espass-espass+zip	[Marcus_Ligi_Büschleb]
494	application	vnd.eszigno3+xml	application/vnd.eszigno3+xml	[Szilveszter_Tóth]
495	application	vnd.etsi.aoc+xml	application/vnd.etsi.aoc+xml	[Shicheng_Hu]
496	application	vnd.etsi.asic-s+zip	application/vnd.etsi.asic-s+zip	[Miguel_Angel_Reina_Ortega]
497	application	vnd.etsi.asic-e+zip	application/vnd.etsi.asic-e+zip	[Miguel_Angel_Reina_Ortega]
498	application	vnd.etsi.cug+xml	application/vnd.etsi.cug+xml	[Shicheng_Hu]
499	application	vnd.etsi.iptvcommand+xml	application/vnd.etsi.iptvcommand+xml	[Shicheng_Hu]
500	application	vnd.etsi.iptvdiscovery+xml	application/vnd.etsi.iptvdiscovery+xml	[Shicheng_Hu]
501	application	vnd.etsi.iptvprofile+xml	application/vnd.etsi.iptvprofile+xml	[Shicheng_Hu]
502	application	vnd.etsi.iptvsad-bc+xml	application/vnd.etsi.iptvsad-bc+xml	[Shicheng_Hu]
503	application	vnd.etsi.iptvsad-cod+xml	application/vnd.etsi.iptvsad-cod+xml	[Shicheng_Hu]
504	application	vnd.etsi.iptvsad-npvr+xml	application/vnd.etsi.iptvsad-npvr+xml	[Shicheng_Hu]
505	application	vnd.etsi.iptvservice+xml	application/vnd.etsi.iptvservice+xml	[Miguel_Angel_Reina_Ortega]
506	application	vnd.etsi.iptvsync+xml	application/vnd.etsi.iptvsync+xml	[Miguel_Angel_Reina_Ortega]
507	application	vnd.etsi.iptvueprofile+xml	application/vnd.etsi.iptvueprofile+xml	[Shicheng_Hu]
508	application	vnd.etsi.mcid+xml	application/vnd.etsi.mcid+xml	[Shicheng_Hu]
509	application	vnd.etsi.mheg5	application/vnd.etsi.mheg5	[Miguel_Angel_Reina_Ortega][Ian_Medland]
510	application	vnd.etsi.overload-control-policy-dataset+xml	application/vnd.etsi.overload-control-policy-dataset+xml	[Miguel_Angel_Reina_Ortega]
511	application	vnd.etsi.pstn+xml	application/vnd.etsi.pstn+xml	[Jiwan_Han][Thomas_Belling]
512	application	vnd.etsi.sci+xml	application/vnd.etsi.sci+xml	[Shicheng_Hu]
513	application	vnd.etsi.simservs+xml	application/vnd.etsi.simservs+xml	[Shicheng_Hu]
514	application	vnd.etsi.timestamp-token	application/vnd.etsi.timestamp-token	[Miguel_Angel_Reina_Ortega]
515	application	vnd.etsi.tsl+xml	application/vnd.etsi.tsl+xml	[Shicheng_Hu]
516	application	vnd.etsi.tsl.der	application/vnd.etsi.tsl.der	[Shicheng_Hu]
517	application	vnd.eudora.data	application/vnd.eudora.data	[Pete_Resnick]
518	application	vnd.ezpix-album	application/vnd.ezpix-album	[ElectronicZombieCorp]
519	application	vnd.ezpix-package	application/vnd.ezpix-package	[ElectronicZombieCorp]
520	application	vnd.f-secure.mobile	application/vnd.f-secure.mobile	[Samu_Sarivaara]
521	application	vnd.fastcopy-disk-image	application/vnd.fastcopy-disk-image	[Thomas_Huth]
522	application	vnd.fdf	application/vnd-fdf	[Steve_Zilles]
523	application	vnd.fdsn.mseed	application/vnd.fdsn.mseed	[Chad_Trabant]
524	application	vnd.fdsn.seed	application/vnd.fdsn.seed	[Chad_Trabant]
525	application	vnd.ffsns	application/vnd.ffsns	[Holstage]
526	application	vnd.filmit.zfc	application/vnd.filmit.zfc	[Harms_Moeller]
527	application	vnd.fints	application/vnd.fints	[Ingo_Hammann]
528	application	vnd.firemonkeys.cloudcell	application/vnd.firemonkeys.cloudcell	[Alex_Dubov]
529	application	vnd.FloGraphIt	application/vnd.FloGraphIt	[Dick_Floersch]
530	application	vnd.fluxtime.clip	application/vnd.fluxtime.clip	[Marc_Winter]
531	application	vnd.font-fontforge-sfd	application/vnd.font-fontforge-sfd	[George_Williams]
532	application	vnd.framemaker	application/vnd.framemaker	[Mike_Wexler]
533	application	vnd.frogans.fnc	application/vnd.frogans.fnc	[Alexis_Tamas]
534	application	vnd.frogans.ltf	application/vnd.frogans.ltf	[Alexis_Tamas]
535	application	vnd.fsc.weblaunch	application/vnd.fsc.weblaunch	[Derek_Smith]
536	application	vnd.fujitsu.oasys	application/vnd.fujitsu.oasys	[Nobukazu_Togashi]
537	application	vnd.fujitsu.oasys2	application/vnd.fujitsu.oasys2	[Nobukazu_Togashi]
538	application	vnd.fujitsu.oasys3	application/vnd.fujitsu.oasys3	[Seiji_Okudaira]
539	application	vnd.fujitsu.oasysgp	application/vnd.fujitsu.oasysgp	[Masahiko_Sugimoto]
540	application	vnd.fujitsu.oasysprs	application/vnd.fujitsu.oasysprs	[Masumi_Ogita]
541	application	vnd.fujixerox.ART4	application/vnd.fujixerox.ART4	[Fumio_Tanabe]
542	application	vnd.fujixerox.ART-EX	application/vnd.fujixerox.ART-EX	[Fumio_Tanabe]
543	application	vnd.fujixerox.ddd	application/vnd.fujixerox.ddd	[Masanori_Onda]
544	application	vnd.fujixerox.docuworks	application/vnd.fujixerox.docuworks	[Yasuo_Taguchi]
545	application	vnd.fujixerox.docuworks.binder	application/vnd.fujixerox.docuworks.binder	[Takashi_Matsumoto]
546	application	vnd.fujixerox.docuworks.container	application/vnd.fujixerox.docuworks.container	[Kiyoshi_Tashiro]
547	application	vnd.fujixerox.HBPL	application/vnd.fujixerox.HBPL	[Fumio_Tanabe]
548	application	vnd.fut-misnet	application/vnd.fut-misnet	[Jann_Pruulman]
549	application	vnd.fuzzysheet	application/vnd.fuzzysheet	[Simon_Birtwistle]
550	application	vnd.genomatix.tuxedo	application/vnd.genomatix.tuxedo	[Torben_Frey]
551	application	vnd.geo+json (OBSOLETED by [RFC7946] in favor of application/geo+json)	application/vnd.geo+json	[Sean_Gillies]
552	application	vnd.geocube+xml - OBSOLETED by request	application/vnd.geocube+xml	[Francois_Pirsch]
553	application	vnd.geogebra.file	application/vnd.geogebra.file	[GeoGebra][Yves_Kreis]
554	application	vnd.geogebra.tool	application/vnd.geogebra.tool	[GeoGebra][Yves_Kreis]
555	application	vnd.geometry-explorer	application/vnd.geometry-explorer	[Michael_Hvidsten]
556	application	vnd.geonext	application/vnd.geonext	[Matthias_Ehmann]
557	application	vnd.geoplan	application/vnd.geoplan	[Christian_Mercat]
558	application	vnd.geospace	application/vnd.geospace	[Christian_Mercat]
559	application	vnd.gerber	application/vnd.gerber	[Thomas_Weyn]
560	application	vnd.globalplatform.card-content-mgt	application/vnd.globalplatform.card-content-mgt	[Gil_Bernabeu]
561	application	vnd.globalplatform.card-content-mgt-response	application/vnd.globalplatform.card-content-mgt-response	[Gil_Bernabeu]
562	application	vnd.gmx - DEPRECATED	application/vnd.gmx	[Christian_V._Sciberras]
563	application	vnd.google-earth.kml+xml	application/vnd.google-earth.kml+xml	[Michael_Ashbridge]
564	application	vnd.google-earth.kmz	application/vnd.google-earth.kmz	[Michael_Ashbridge]
565	application	vnd.gov.sk.e-form+xml	application/vnd.gov.sk.e-form+xml	[Peter_Biro][Stefan_Szilva]
566	application	vnd.gov.sk.e-form+zip	application/vnd.gov.sk.e-form+zip	[Peter_Biro][Stefan_Szilva]
567	application	vnd.gov.sk.xmldatacontainer+xml	application/vnd.gov.sk.xmldatacontainer+xml	[Peter_Biro][Stefan_Szilva]
568	application	vnd.grafeq	application/vnd.grafeq	[Jeff_Tupper]
569	application	vnd.gridmp	application/vnd.gridmp	[Jeff_Lawson]
570	application	vnd.groove-account	application/vnd.groove-account	[Todd_Joseph]
571	application	vnd.groove-help	application/vnd.groove-help	[Todd_Joseph]
572	application	vnd.groove-identity-message	application/vnd.groove-identity-message	[Todd_Joseph]
573	application	vnd.groove-injector	application/vnd.groove-injector	[Todd_Joseph]
574	application	vnd.groove-tool-message	application/vnd.groove-tool-message	[Todd_Joseph]
575	application	vnd.groove-tool-template	application/vnd.groove-tool-template	[Todd_Joseph]
576	application	vnd.groove-vcard	application/vnd.groove-vcard	[Todd_Joseph]
577	application	vnd.hal+json	application/vnd.hal+json	[Mike_Kelly]
578	application	vnd.hal+xml	application/vnd.hal+xml	[Mike_Kelly]
579	application	vnd.HandHeld-Entertainment+xml	application/vnd.HandHeld-Entertainment+xml	[Eric_Hamilton]
580	application	vnd.hbci	application/vnd.hbci	[Ingo_Hammann]
581	application	vnd.hcl-bireports	application/vnd.hcl-bireports	[Doug_R._Serres]
582	application	vnd.hdt	application/vnd.hdt	[Javier_D._Fernández]
583	application	vnd.heroku+json	application/vnd.heroku+json	[Wesley_Beary]
584	application	vnd.hhe.lesson-player	application/vnd.hhe.lesson-player	[Randy_Jones]
585	application	vnd.hp-HPGL	application/vnd.hp-HPGL	[Bob_Pentecost]
586	application	vnd.hp-hpid	application/vnd.hp-hpid	[Aloke_Gupta]
587	application	vnd.hp-hps	application/vnd.hp-hps	[Steve_Aubrey]
588	application	vnd.hp-jlyt	application/vnd.hp-jlyt	[Amir_Gaash]
589	application	vnd.hp-PCL	application/vnd.hp-PCL	[Bob_Pentecost]
590	application	vnd.hp-PCLXL	application/vnd.hp-PCLXL	[Bob_Pentecost]
591	application	vnd.httphone	application/vnd.httphone	[Franck_Lefevre]
592	application	vnd.hydrostatix.sof-data	application/vnd.hydrostatix.sof-data	[Allen_Gillam]
593	application	vnd.hyperdrive+json	application/vnd.hyperdrive+json	[Daniel_Sims]
594	application	vnd.hzn-3d-crossword	application/vnd.hzn-3d-crossword	[James_Minnis]
595	application	vnd.ibm.afplinedata	application/vnd.ibm.afplinedata	[Roger_Buis]
596	application	vnd.ibm.electronic-media	application/vnd.ibm.electronic-media	[Bruce_Tantlinger]
597	application	vnd.ibm.MiniPay	application/vnd.ibm.MiniPay	[Amir_Herzberg]
598	application	vnd.ibm.modcap	application/vnd.ibm.modcap	[Reinhard_Hohensee]
599	application	vnd.ibm.rights-management	application/vnd.ibm.rights-management	[Bruce_Tantlinger]
600	application	vnd.ibm.secure-container	application/vnd.ibm.secure-container	[Bruce_Tantlinger]
601	application	vnd.iccprofile	application/vnd.iccprofile	[Phil_Green]
602	application	vnd.ieee.1905	application/vnd.ieee.1905	[Purva_R_Rajkotia]
603	application	vnd.igloader	application/vnd.igloader	[Tim_Fisher]
604	application	vnd.immervision-ivp	application/vnd.immervision-ivp	[Mathieu_Villegas]
605	application	vnd.immervision-ivu	application/vnd.immervision-ivu	[Mathieu_Villegas]
606	application	vnd.ims.imsccv1p1	application/vnd.ims.imsccv1p1	[Lisa_Mattson]
607	application	vnd.ims.imsccv1p2	application/vnd.ims.imsccv1p2	[Lisa_Mattson]
608	application	vnd.ims.imsccv1p3	application/vnd.ims.imsccv1p3	[Lisa_Mattson]
609	application	vnd.ims.lis.v2.result+json	application/vnd.ims.lis.v2.result+json	[Lisa_Mattson]
610	application	vnd.ims.lti.v2.toolconsumerprofile+json	application/vnd.ims.lti.v2.toolconsumerprofile+json	[Lisa_Mattson]
611	application	vnd.ims.lti.v2.toolproxy.id+json	application/vnd.ims.lti.v2.toolproxy.id+json	[Lisa_Mattson]
612	application	vnd.ims.lti.v2.toolproxy+json	application/vnd.ims.lti.v2.toolproxy+json	[Lisa_Mattson]
613	application	vnd.ims.lti.v2.toolsettings+json	application/vnd.ims.lti.v2.toolsettings+json	[Lisa_Mattson]
614	application	vnd.ims.lti.v2.toolsettings.simple+json	application/vnd.ims.lti.v2.toolsettings.simple+json	[Lisa_Mattson]
615	application	vnd.informedcontrol.rms+xml	application/vnd.informedcontrol.rms+xml	[Mark_Wahl]
616	application	vnd.infotech.project	application/vnd.infotech.project	[Charles_Engelke]
617	application	vnd.infotech.project+xml	application/vnd.infotech.project+xml	[Charles_Engelke]
618	application	vnd.informix-visionary - OBSOLETED in favor of application/vnd.visionary	application/vnd.informix-visionary	[Christopher_Gales]
619	application	vnd.innopath.wamp.notification	application/vnd.innopath.wamp.notification	[Takanori_Sudo]
620	application	vnd.insors.igm	application/vnd.insors.igm	[Jon_Swanson]
621	application	vnd.intercon.formnet	application/vnd.intercon.formnet	[Tom_Gurak]
622	application	vnd.intergeo	application/vnd.intergeo	[Yves_Kreis_2]
623	application	vnd.intertrust.digibox	application/vnd.intertrust.digibox	[Luke_Tomasello]
624	application	vnd.intertrust.nncp	application/vnd.intertrust.nncp	[Luke_Tomasello]
625	application	vnd.intu.qbo	application/vnd.intu.qbo	[Greg_Scratchley]
626	application	vnd.intu.qfx	application/vnd.intu.qfx	[Greg_Scratchley]
627	application	vnd.iptc.g2.catalogitem+xml	application/vnd.iptc.g2.catalogitem+xml	[Michael_Steidl]
628	application	vnd.iptc.g2.conceptitem+xml	application/vnd.iptc.g2.conceptitem+xml	[Michael_Steidl]
629	application	vnd.iptc.g2.knowledgeitem+xml	application/vnd.iptc.g2.knowledgeitem+xml	[Michael_Steidl]
630	application	vnd.iptc.g2.newsitem+xml	application/vnd.iptc.g2.newsitem+xml	[Michael_Steidl]
631	application	vnd.iptc.g2.newsmessage+xml	application/vnd.iptc.g2.newsmessage+xml	[Michael_Steidl]
632	application	vnd.iptc.g2.packageitem+xml	application/vnd.iptc.g2.packageitem+xml	[Michael_Steidl]
633	application	vnd.iptc.g2.planningitem+xml	application/vnd.iptc.g2.planningitem+xml	[Michael_Steidl]
634	application	vnd.ipunplugged.rcprofile	application/vnd.ipunplugged.rcprofile	[Per_Ersson]
635	application	vnd.irepository.package+xml	application/vnd.irepository.package+xml	[Martin_Knowles]
636	application	vnd.is-xpr	application/vnd.is-xpr	[Satish_Navarajan]
637	application	vnd.isac.fcs	application/vnd.isac.fcs	[Ryan_Brinkman]
638	application	vnd.jam	application/vnd.jam	[Brijesh_Kumar]
639	application	vnd.japannet-directory-service	application/vnd.japannet-directory-service	[Kiyofusa_Fujii]
640	application	vnd.japannet-jpnstore-wakeup	application/vnd.japannet-jpnstore-wakeup	[Jun_Yoshitake]
641	application	vnd.japannet-payment-wakeup	application/vnd.japannet-payment-wakeup	[Kiyofusa_Fujii]
642	application	vnd.japannet-registration	application/vnd.japannet-registration	[Jun_Yoshitake]
643	application	vnd.japannet-registration-wakeup	application/vnd.japannet-registration-wakeup	[Kiyofusa_Fujii]
644	application	vnd.japannet-setstore-wakeup	application/vnd.japannet-setstore-wakeup	[Jun_Yoshitake]
645	application	vnd.japannet-verification	application/vnd.japannet-verification	[Jun_Yoshitake]
646	application	vnd.japannet-verification-wakeup	application/vnd.japannet-verification-wakeup	[Kiyofusa_Fujii]
647	application	vnd.jcp.javame.midlet-rms	application/vnd.jcp.javame.midlet-rms	[Mikhail_Gorshenev]
648	application	vnd.jisp	application/vnd.jisp	[Sebastiaan_Deckers]
649	application	vnd.joost.joda-archive	application/vnd.joost.joda-archive	[Joost]
650	application	vnd.jsk.isdn-ngn	application/vnd.jsk.isdn-ngn	[Yokoyama_Kiyonobu]
651	application	vnd.kahootz	application/vnd.kahootz	[Tim_Macdonald]
652	application	vnd.kde.karbon	application/vnd.kde.karbon	[David_Faure]
653	application	vnd.kde.kchart	application/vnd.kde.kchart	[David_Faure]
654	application	vnd.kde.kformula	application/vnd.kde.kformula	[David_Faure]
655	application	vnd.kde.kivio	application/vnd.kde.kivio	[David_Faure]
656	application	vnd.kde.kontour	application/vnd.kde.kontour	[David_Faure]
657	application	vnd.kde.kpresenter	application/vnd.kde.kpresenter	[David_Faure]
658	application	vnd.kde.kspread	application/vnd.kde.kspread	[David_Faure]
659	application	vnd.kde.kword	application/vnd.kde.kword	[David_Faure]
660	application	vnd.kenameaapp	application/vnd.kenameaapp	[Dirk_DiGiorgio-Haag]
661	application	vnd.kidspiration	application/vnd.kidspiration	[Jack_Bennett]
662	application	vnd.Kinar	application/vnd.Kinar	[Hemant_Thakkar]
663	application	vnd.koan	application/vnd.koan	[Pete_Cole]
664	application	vnd.kodak-descriptor	application/vnd.kodak-descriptor	[Michael_J._Donahue]
665	application	vnd.las.las+xml	application/vnd.las.las+xml	[Rob_Bailey]
666	application	vnd.liberty-request+xml	application/vnd.liberty-request+xml	[Brett_McDowell]
667	application	vnd.llamagraphics.life-balance.desktop	application/vnd.llamagraphics.life-balance.desktop	[Catherine_E._White]
668	application	vnd.llamagraphics.life-balance.exchange+xml	application/vnd.llamagraphics.life-balance.exchange+xml	[Catherine_E._White]
669	application	vnd.lotus-1-2-3	application/vnd.lotus-1-2-3	[Paul_Wattenberger]
670	application	vnd.lotus-approach	application/vnd.lotus-approach	[Paul_Wattenberger]
671	application	vnd.lotus-freelance	application/vnd.lotus-freelance	[Paul_Wattenberger]
672	application	vnd.lotus-notes	application/vnd.lotus-notes	[Michael_Laramie]
673	application	vnd.lotus-organizer	application/vnd.lotus-organizer	[Paul_Wattenberger]
674	application	vnd.lotus-screencam	application/vnd.lotus-screencam	[Paul_Wattenberger]
675	application	vnd.lotus-wordpro	application/vnd.lotus-wordpro	[Paul_Wattenberger]
676	application	vnd.macports.portpkg	application/vnd.macports.portpkg	[James_Berry]
677	application	vnd.macports.portpkg	application/vnd.macports.portpkg	[James_Berry]
678	application	vnd.mapbox-vector-tile	application/vnd.mapbox-vector-tile	[Blake_Thompson]
679	application	vnd.marlin.drm.actiontoken+xml	application/vnd.marlin.drm.actiontoken+xml	[Gary_Ellison]
680	application	vnd.marlin.drm.conftoken+xml	application/vnd.marlin.drm.conftoken+xml	[Gary_Ellison]
681	application	vnd.marlin.drm.license+xml	application/vnd.marlin.drm.license+xml	[Gary_Ellison]
682	application	vnd.marlin.drm.mdcf	application/vnd.marlin.drm.mdcf	[Gary_Ellison]
683	application	vnd.mason+json	application/vnd.mason+json	[Jorn_Wildt]
684	application	vnd.maxmind.maxmind-db	application/vnd.maxmind.maxmind-db	[William_Stevenson]
685	application	vnd.mcd	application/vnd.mcd	[Tadashi_Gotoh]
686	application	vnd.medcalcdata	application/vnd.medcalcdata	[Frank_Schoonjans]
687	application	vnd.mediastation.cdkey	application/vnd.mediastation.cdkey	[Henry_Flurry]
688	application	vnd.meridian-slingshot	application/vnd.meridian-slingshot	[Eric_Wedel]
689	application	vnd.MFER	application/vnd.MFER	[Masaaki_Hirai]
690	application	vnd.mfmp	application/vnd.mfmp	[Yukari_Ikeda]
691	application	vnd.micro+json	application/vnd.micro+json	[Dali_Zheng]
692	application	vnd.micrografx.flo	application/vnd.micrografx.flo	[Joe_Prevo]
693	application	vnd.micrografx.igx	application/vnd.micrografx-igx	[Joe_Prevo]
694	application	vnd.microsoft.portable-executable	application/vnd.microsoft.portable-executable	[Henrik_Andersson]
695	application	vnd.miele+json	application/vnd.miele+json	[Nils_Langhammer]
696	application	vnd.mif	application/vnd-mif	[Mike_Wexler]
697	application	vnd.minisoft-hp3000-save	application/vnd.minisoft-hp3000-save	[Chris_Bartram]
698	application	vnd.mitsubishi.misty-guard.trustweb	application/vnd.mitsubishi.misty-guard.trustweb	[Tanaka]
699	application	vnd.Mobius.DAF	application/vnd.Mobius.DAF	[Allen_K._Kabayama]
700	application	vnd.Mobius.DIS	application/vnd.Mobius.DIS	[Allen_K._Kabayama]
701	application	vnd.Mobius.MBK	application/vnd.Mobius.MBK	[Alex_Devasia]
702	application	vnd.Mobius.MQY	application/vnd.Mobius.MQY	[Alex_Devasia]
703	application	vnd.Mobius.MSL	application/vnd.Mobius.MSL	[Allen_K._Kabayama]
704	application	vnd.Mobius.PLC	application/vnd.Mobius.PLC	[Allen_K._Kabayama]
705	application	vnd.Mobius.TXF	application/vnd.Mobius.TXF	[Allen_K._Kabayama]
706	application	vnd.mophun.application	application/vnd.mophun.application	[Bjorn_Wennerstrom]
707	application	vnd.mophun.certificate	application/vnd.mophun.certificate	[Bjorn_Wennerstrom]
708	application	vnd.motorola.flexsuite	application/vnd.motorola.flexsuite	[Mark_Patton]
709	application	vnd.motorola.flexsuite.adsi	application/vnd.motorola.flexsuite.adsi	[Mark_Patton]
710	application	vnd.motorola.flexsuite.fis	application/vnd.motorola.flexsuite.fis	[Mark_Patton]
711	application	vnd.motorola.flexsuite.gotap	application/vnd.motorola.flexsuite.gotap	[Mark_Patton]
712	application	vnd.motorola.flexsuite.kmr	application/vnd.motorola.flexsuite.kmr	[Mark_Patton]
713	application	vnd.motorola.flexsuite.ttc	application/vnd.motorola.flexsuite.ttc	[Mark_Patton]
714	application	vnd.motorola.flexsuite.wem	application/vnd.motorola.flexsuite.wem	[Mark_Patton]
715	application	vnd.motorola.iprm	application/vnd.motorola.iprm	[Rafie_Shamsaasef]
716	application	vnd.mozilla.xul+xml	application/vnd.mozilla.xul+xml	[Braden_N_McDaniel]
717	application	vnd.ms-artgalry	application/vnd.ms-artgalry	[Dean_Slawson]
718	application	vnd.ms-asf	application/vnd.ms-asf	[Eric_Fleischman]
719	application	vnd.ms-cab-compressed	application/vnd.ms-cab-compressed	[Kim_Scarborough]
720	application	vnd.ms-3mfdocument	application/vnd.ms-3mfdocument	[Shawn_Maloney]
721	application	vnd.ms-excel	application/vnd.ms-excel	[Sukvinder_S._Gill]
722	application	vnd.ms-excel.addin.macroEnabled.12	application/vnd.ms-excel.addin.macroEnabled.12	[Chris_Rae]
723	application	vnd.ms-excel.sheet.binary.macroEnabled.12	application/vnd.ms-excel.sheet.binary.macroEnabled.12	[Chris_Rae]
724	application	vnd.ms-excel.sheet.macroEnabled.12	application/vnd.ms-excel.sheet.macroEnabled.12	[Chris_Rae]
725	application	vnd.ms-excel.template.macroEnabled.12	application/vnd.ms-excel.template.macroEnabled.12	[Chris_Rae]
726	application	vnd.ms-fontobject	application/vnd.ms-fontobject	[Kim_Scarborough]
727	application	vnd.ms-htmlhelp	application/vnd.ms-htmlhelp	[Anatoly_Techtonik]
728	application	vnd.ms-ims	application/vnd.ms-ims	[Eric_Ledoux]
729	application	vnd.ms-lrm	application/vnd.ms-lrm	[Eric_Ledoux]
730	application	vnd.ms-office.activeX+xml	application/vnd.ms-office.activeX+xml	[Chris_Rae]
731	application	vnd.ms-officetheme	application/vnd.ms-officetheme	[Chris_Rae]
732	application	vnd.ms-playready.initiator+xml	application/vnd.ms-playready.initiator+xml	[Daniel_Schneider]
733	application	vnd.ms-powerpoint	application/vnd.ms-powerpoint	[Sukvinder_S._Gill]
734	application	vnd.ms-powerpoint.addin.macroEnabled.12	application/vnd.ms-powerpoint.addin.macroEnabled.12	[Chris_Rae]
735	application	vnd.ms-powerpoint.presentation.macroEnabled.12	application/vnd.ms-powerpoint.presentation.macroEnabled.12	[Chris_Rae]
736	application	vnd.ms-powerpoint.slide.macroEnabled.12	application/vnd.ms-powerpoint.slide.macroEnabled.12	[Chris_Rae]
737	application	vnd.ms-powerpoint.slideshow.macroEnabled.12	application/vnd.ms-powerpoint.slideshow.macroEnabled.12	[Chris_Rae]
738	application	vnd.ms-powerpoint.template.macroEnabled.12	application/vnd.ms-powerpoint.template.macroEnabled.12	[Chris_Rae]
739	application	vnd.ms-PrintDeviceCapabilities+xml	application/vnd.ms-PrintDeviceCapabilities+xml	[Justin_Hutchings]
740	application	vnd.ms-PrintSchemaTicket+xml	application/vnd.ms-PrintSchemaTicket+xml	[Justin_Hutchings]
741	application	vnd.ms-project	application/vnd.ms-project	[Sukvinder_S._Gill]
742	application	vnd.ms-tnef	application/vnd.ms-tnef	[Sukvinder_S._Gill]
743	application	vnd.ms-windows.devicepairing	application/vnd.ms-windows.devicepairing	[Justin_Hutchings]
744	application	vnd.ms-windows.nwprinting.oob	application/vnd.ms-windows.nwprinting.oob	[Justin_Hutchings]
745	application	vnd.ms-windows.printerpairing	application/vnd.ms-windows.printerpairing	[Justin_Hutchings]
746	application	vnd.ms-windows.wsd.oob	application/vnd.ms-windows.wsd.oob	[Justin_Hutchings]
747	application	vnd.ms-wmdrm.lic-chlg-req	application/vnd.ms-wmdrm.lic-chlg-req	[Kevin_Lau]
748	application	vnd.ms-wmdrm.lic-resp	application/vnd.ms-wmdrm.lic-resp	[Kevin_Lau]
749	application	vnd.ms-wmdrm.meter-chlg-req	application/vnd.ms-wmdrm.meter-chlg-req	[Kevin_Lau]
750	application	vnd.ms-wmdrm.meter-resp	application/vnd.ms-wmdrm.meter-resp	[Kevin_Lau]
751	application	vnd.ms-word.document.macroEnabled.12	application/vnd.ms-word.document.macroEnabled.12	[Chris_Rae]
752	application	vnd.ms-word.template.macroEnabled.12	application/vnd.ms-word.template.macroEnabled.12	[Chris_Rae]
753	application	vnd.ms-works	application/vnd.ms-works	[Sukvinder_S._Gill]
754	application	vnd.ms-wpl	application/vnd.ms-wpl	[Dan_Plastina]
755	application	vnd.ms-xpsdocument	application/vnd.ms-xpsdocument	[Jesse_McGatha]
756	application	vnd.msa-disk-image	application/vnd.msa-disk-image	[Thomas_Huth]
757	application	vnd.mseq	application/vnd.mseq	[Gwenael_Le_Bodic]
758	application	vnd.msign	application/vnd.msign	[Malte_Borcherding]
759	application	vnd.multiad.creator	application/vnd.multiad.creator	[Steve_Mills]
760	application	vnd.multiad.creator.cif	application/vnd.multiad.creator.cif	[Steve_Mills]
761	application	vnd.musician	application/vnd.musician	[Greg_Adams]
762	application	vnd.music-niff	application/vnd.music-niff	[Tim_Butler]
763	application	vnd.muvee.style	application/vnd.muvee.style	[Chandrashekhara_Anantharamu]
764	application	vnd.mynfc	application/vnd.mynfc	[Franck_Lefevre]
765	application	vnd.ncd.control	application/vnd.ncd.control	[Lauri_Tarkkala]
766	application	vnd.ncd.reference	application/vnd.ncd.reference	[Lauri_Tarkkala]
767	application	vnd.nearst.inv+json	application/vnd.nearst.inv+json	[Thomas_Schoffelen]
768	application	vnd.nervana	application/vnd.nervana	[Steve_Judkins]
769	application	vnd.netfpx	application/vnd.netfpx	[Andy_Mutz]
770	application	vnd.neurolanguage.nlu	application/vnd.neurolanguage.nlu	[Dan_DuFeu]
771	application	vnd.nintendo.snes.rom	application/vnd.nintendo.snes.rom	[Henrik_Andersson]
772	application	vnd.nintendo.nitro.rom	application/vnd.nintendo.nitro.rom	[Henrik_Andersson]
773	application	vnd.nitf	application/vnd.nitf	[Steve_Rogan]
774	application	vnd.noblenet-directory	application/vnd.noblenet-directory	[Monty_Solomon]
775	application	vnd.noblenet-sealer	application/vnd.noblenet-sealer	[Monty_Solomon]
776	application	vnd.noblenet-web	application/vnd.noblenet-web	[Monty_Solomon]
777	application	vnd.nokia.catalogs	application/vnd.nokia.catalogs	[Nokia]
778	application	vnd.nokia.conml+wbxml	application/vnd.nokia.conml+wbxml	[Nokia]
779	application	vnd.nokia.conml+xml	application/vnd.nokia.conml+xml	[Nokia]
780	application	vnd.nokia.iptv.config+xml	application/vnd.nokia.iptv.config+xml	[Nokia]
781	application	vnd.nokia.iSDS-radio-presets	application/vnd.nokia.iSDS-radio-presets	[Nokia]
782	application	vnd.nokia.landmark+wbxml	application/vnd.nokia.landmark+wbxml	[Nokia]
783	application	vnd.nokia.landmark+xml	application/vnd.nokia.landmark+xml	[Nokia]
784	application	vnd.nokia.landmarkcollection+xml	application/vnd.nokia.landmarkcollection+xml	[Nokia]
785	application	vnd.nokia.ncd	application/vnd.nokia.ncd	[Nokia]
786	application	vnd.nokia.n-gage.ac+xml	application/vnd.nokia.n-gage.ac+xml	[Nokia]
787	application	vnd.nokia.n-gage.data	application/vnd.nokia.n-gage.data	[Nokia]
788	application	vnd.nokia.n-gage.symbian.install - OBSOLETE; no replacement given	application/vnd.nokia.n-gage.symbian.install	[Nokia]
789	application	vnd.nokia.pcd+wbxml	application/vnd.nokia.pcd+wbxml	[Nokia]
790	application	vnd.nokia.pcd+xml	application/vnd.nokia.pcd+xml	[Nokia]
791	application	vnd.nokia.radio-preset	application/vnd.nokia.radio-preset	[Nokia]
792	application	vnd.nokia.radio-presets	application/vnd.nokia.radio-presets	[Nokia]
793	application	vnd.novadigm.EDM	application/vnd.novadigm.EDM	[Janine_Swenson]
794	application	vnd.novadigm.EDX	application/vnd.novadigm.EDX	[Janine_Swenson]
795	application	vnd.novadigm.EXT	application/vnd.novadigm.EXT	[Janine_Swenson]
796	application	vnd.ntt-local.content-share	application/vnd.ntt-local.content-share	[Akinori_Taya]
797	application	vnd.ntt-local.file-transfer	application/vnd.ntt-local.file-transfer	[NTT-local]
798	application	vnd.ntt-local.ogw_remote-access	application/vnd.ntt-local.ogw_remote-access	[NTT-local]
799	application	vnd.ntt-local.sip-ta_remote	application/vnd.ntt-local.sip-ta_remote	[NTT-local]
800	application	vnd.ntt-local.sip-ta_tcp_stream	application/vnd.ntt-local.sip-ta_tcp_stream	[NTT-local]
801	application	vnd.oasis.opendocument.chart	application/vnd.oasis.opendocument.chart	[Svante_Schubert][OASIS]
802	application	vnd.oasis.opendocument.chart-template	application/vnd.oasis.opendocument.chart-template	[Svante_Schubert][OASIS]
803	application	vnd.oasis.opendocument.database	application/vnd.oasis.opendocument.database	[Svante_Schubert][OASIS]
804	application	vnd.oasis.opendocument.formula	application/vnd.oasis.opendocument.formula	[Svante_Schubert][OASIS]
805	application	vnd.oasis.opendocument.formula-template	application/vnd.oasis.opendocument.formula-template	[Svante_Schubert][OASIS]
806	application	vnd.oasis.opendocument.graphics	application/vnd.oasis.opendocument.graphics	[Svante_Schubert][OASIS]
807	application	vnd.oasis.opendocument.graphics-template	application/vnd.oasis.opendocument.graphics-template	[Svante_Schubert][OASIS]
808	application	vnd.oasis.opendocument.image	application/vnd.oasis.opendocument.image	[Svante_Schubert][OASIS]
809	application	vnd.oasis.opendocument.image-template	application/vnd.oasis.opendocument.image-template	[Svante_Schubert][OASIS]
810	application	vnd.oasis.opendocument.presentation	application/vnd.oasis.opendocument.presentation	[Svante_Schubert][OASIS]
811	application	vnd.oasis.opendocument.presentation-template	application/vnd.oasis.opendocument.presentation-template	[Svante_Schubert][OASIS]
812	application	vnd.oasis.opendocument.spreadsheet	application/vnd.oasis.opendocument.spreadsheet	[Svante_Schubert][OASIS]
813	application	vnd.oasis.opendocument.spreadsheet-template	application/vnd.oasis.opendocument.spreadsheet-template	[Svante_Schubert][OASIS]
814	application	vnd.oasis.opendocument.text	application/vnd.oasis.opendocument.text	[Svante_Schubert][OASIS]
815	application	vnd.oasis.opendocument.text-master	application/vnd.oasis.opendocument.text-master	[Svante_Schubert][OASIS]
816	application	vnd.oasis.opendocument.text-template	application/vnd.oasis.opendocument.text-template	[Svante_Schubert][OASIS]
817	application	vnd.oasis.opendocument.text-web	application/vnd.oasis.opendocument.text-web	[Svante_Schubert][OASIS]
818	application	vnd.obn	application/vnd.obn	[Matthias_Hessling]
819	application	vnd.oftn.l10n+json	application/vnd.oftn.l10n+json	[Eli_Grey]
820	application	vnd.oipf.contentaccessdownload+xml	application/vnd.oipf.contentaccessdownload+xml	[Claire_DEsclercs]
821	application	vnd.oipf.contentaccessstreaming+xml	application/vnd.oipf.contentaccessstreaming+xml	[Claire_DEsclercs]
822	application	vnd.oipf.cspg-hexbinary	application/vnd.oipf.cspg-hexbinary	[Claire_DEsclercs]
823	application	vnd.oipf.dae.svg+xml	application/vnd.oipf.dae.svg+xml	[Claire_DEsclercs]
824	application	vnd.oipf.dae.xhtml+xml	application/vnd.oipf.dae.xhtml+xml	[Claire_DEsclercs]
825	application	vnd.oipf.mippvcontrolmessage+xml	application/vnd.oipf.mippvcontrolmessage+xml	[Claire_DEsclercs]
826	application	vnd.oipf.pae.gem	application/vnd.oipf.pae.gem	[Claire_DEsclercs]
827	application	vnd.oipf.spdiscovery+xml	application/vnd.oipf.spdiscovery+xml	[Claire_DEsclercs]
828	application	vnd.oipf.spdlist+xml	application/vnd.oipf.spdlist+xml	[Claire_DEsclercs]
829	application	vnd.oipf.ueprofile+xml	application/vnd.oipf.ueprofile+xml	[Claire_DEsclercs]
830	application	vnd.oipf.userprofile+xml	application/vnd.oipf.userprofile+xml	[Claire_DEsclercs]
831	application	vnd.olpc-sugar	application/vnd.olpc-sugar	[John_Palmieri]
832	application	vnd.oma.bcast.associated-procedure-parameter+xml	application/vnd.oma.bcast.associated-procedure-parameter+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
833	application	vnd.oma.bcast.drm-trigger+xml	application/vnd.oma.bcast.drm-trigger+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
834	application	vnd.oma.bcast.imd+xml	application/vnd.oma.bcast.imd+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
835	application	vnd.oma.bcast.ltkm	application/vnd.oma.bcast.ltkm	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
836	application	vnd.oma.bcast.notification+xml	application/vnd.oma.bcast.notification+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
837	application	vnd.oma.bcast.provisioningtrigger	application/vnd.oma.bcast.provisioningtrigger	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
838	application	vnd.oma.bcast.sgboot	application/vnd.oma.bcast.sgboot	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
839	application	vnd.oma.bcast.sgdd+xml	application/vnd.oma.bcast.sgdd+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
840	application	vnd.oma.bcast.sgdu	application/vnd.oma.bcast.sgdu	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
841	application	vnd.oma.bcast.simple-symbol-container	application/vnd.oma.bcast.simple-symbol-container	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
842	application	vnd.oma.bcast.smartcard-trigger+xml	application/vnd.oma.bcast.smartcard-trigger+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
843	application	vnd.oma.bcast.sprov+xml	application/vnd.oma.bcast.sprov+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
844	application	vnd.oma.bcast.stkm	application/vnd.oma.bcast.stkm	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
845	application	vnd.oma.cab-address-book+xml	application/vnd.oma.cab-address-book+xml	[Hao_Wang][OMA]
846	application	vnd.oma.cab-feature-handler+xml	application/vnd.oma.cab-feature-handler+xml	[Hao_Wang][OMA]
847	application	vnd.oma.cab-pcc+xml	application/vnd.oma.cab-pcc+xml	[Hao_Wang][OMA]
848	application	vnd.oma.cab-subs-invite+xml	application/vnd.oma.cab-subs-invite+xml	[Hao_Wang][OMA]
849	application	vnd.oma.cab-user-prefs+xml	application/vnd.oma.cab-user-prefs+xml	[Hao_Wang][OMA]
850	application	vnd.oma.dcd	application/vnd.oma.dcd	[Avi_Primo][Open_Mobile_Naming_Authority]
851	application	vnd.oma.dcdc	application/vnd.oma.dcdc	[Avi_Primo][Open_Mobile_Naming_Authority]
852	application	vnd.oma.dd2+xml	application/vnd.oma.dd2+xml	[Jun_Sato][Open_Mobile_Alliance_BAC_DLDRM_Working_Group]
853	application	vnd.oma.drm.risd+xml	application/vnd.oma.drm.risd+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
854	application	vnd.oma.group-usage-list+xml	application/vnd.oma.group-usage-list+xml	[Sean_Kelley][OMA_Presence_and_Availability_PAG_Working_Group]
855	application	vnd.oma.lwm2m+json	application/vnd.oma.lwm2m+json	[John_Mudge][Open_Mobile_Naming_Authority]
856	application	vnd.oma.lwm2m+tlv	application/vnd.oma.lwm2m+tlv	[John_Mudge][Open_Mobile_Naming_Authority]
857	application	vnd.oma.pal+xml	application/vnd.oma.pal+xml	[Brian_McColgan][Open_Mobile_Naming_Authority]
858	application	vnd.oma.poc.detailed-progress-report+xml	application/vnd.oma.poc.detailed-progress-report+xml	[OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
859	application	vnd.oma.poc.final-report+xml	application/vnd.oma.poc.final-report+xml	[OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
860	application	vnd.oma.poc.groups+xml	application/vnd.oma.poc.groups+xml	[Sean_Kelley][OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
861	application	vnd.oma.poc.invocation-descriptor+xml	application/vnd.oma.poc.invocation-descriptor+xml	[OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
1014	application	vnd.route66.link66+xml	application/vnd.route66.link66+xml	[Sybren_Kikstra]
862	application	vnd.oma.poc.optimized-progress-report+xml	application/vnd.oma.poc.optimized-progress-report+xml	[OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
863	application	vnd.oma.push	application/vnd.oma.push	[Bryan_Sullivan][OMA]
864	application	vnd.oma.scidm.messages+xml	application/vnd.oma.scidm.messages+xml	[Wenjun_Zeng][Open_Mobile_Naming_Authority]
865	application	vnd.oma.xcap-directory+xml	application/vnd.oma.xcap-directory+xml	[Sean_Kelley][OMA_Presence_and_Availability_PAG_Working_Group]
866	application	vnd.omads-email+xml	application/vnd.omads-email+xml	[OMA_Data_Synchronization_Working_Group]
867	application	vnd.omads-file+xml	application/vnd.omads-file+xml	[OMA_Data_Synchronization_Working_Group]
868	application	vnd.omads-folder+xml	application/vnd.omads-folder+xml	[OMA_Data_Synchronization_Working_Group]
869	application	vnd.omaloc-supl-init	application/vnd.omaloc-supl-init	[Julien_Grange]
870	application	vnd.oma-scws-config	application/vnd.oma-scws-config	[Ilan_Mahalal]
871	application	vnd.oma-scws-http-request	application/vnd.oma-scws-http-request	[Ilan_Mahalal]
872	application	vnd.oma-scws-http-response	application/vnd.oma-scws-http-response	[Ilan_Mahalal]
873	application	vnd.onepager	application/vnd.onepager	[Nathan_Black]
874	application	vnd.openblox.game-binary	application/vnd.openblox.game-binary	[Mark_Otaris]
875	application	vnd.openblox.game+xml	application/vnd.openblox.game+xml	[Mark_Otaris]
876	application	vnd.openeye.oeb	application/vnd.openeye.oeb	[Craig_Bruce]
877	application	vnd.openstreetmap.data+xml	application/vnd.openstreetmap.data+xml	[Paul_Norman]
878	application	vnd.openxmlformats-officedocument.custom-properties+xml	application/vnd.openxmlformats-officedocument.custom-properties+xml	[Makoto_Murata]
879	application	vnd.openxmlformats-officedocument.customXmlProperties+xml	application/vnd.openxmlformats-officedocument.customXmlProperties+xml	[Makoto_Murata]
880	application	vnd.openxmlformats-officedocument.drawing+xml	application/vnd.openxmlformats-officedocument.drawing+xml	[Makoto_Murata]
881	application	vnd.openxmlformats-officedocument.drawingml.chart+xml	application/vnd.openxmlformats-officedocument.drawingml.chart+xml	[Makoto_Murata]
882	application	vnd.openxmlformats-officedocument.drawingml.chartshapes+xml	application/vnd.openxmlformats-officedocument.drawingml.chartshapes+xml	[Makoto_Murata]
883	application	vnd.openxmlformats-officedocument.drawingml.diagramColors+xml	application/vnd.openxmlformats-officedocument.drawingml.diagramColors+xml	[Makoto_Murata]
884	application	vnd.openxmlformats-officedocument.drawingml.diagramData+xml	application/vnd.openxmlformats-officedocument.drawingml.diagramData+xml	[Makoto_Murata]
885	application	vnd.openxmlformats-officedocument.drawingml.diagramLayout+xml	application/vnd.openxmlformats-officedocument.drawingml.diagramLayout+xml	[Makoto_Murata]
886	application	vnd.openxmlformats-officedocument.drawingml.diagramStyle+xml	application/vnd.openxmlformats-officedocument.drawingml.diagramStyle+xml	[Makoto_Murata]
887	application	vnd.openxmlformats-officedocument.extended-properties+xml	application/vnd.openxmlformats-officedocument.extended-properties+xml	[Makoto_Murata]
888	application	vnd.openxmlformats-officedocument.presentationml.commentAuthors+xml	application/vnd.openxmlformats-officedocument.presentationml.commentAuthors+xml	[Makoto_Murata]
889	application	vnd.openxmlformats-officedocument.presentationml.comments+xml	application/vnd.openxmlformats-officedocument.presentationml.comments+xml	[Makoto_Murata]
890	application	vnd.openxmlformats-officedocument.presentationml.handoutMaster+xml	application/vnd.openxmlformats-officedocument.presentationml.handoutMaster+xml	[Makoto_Murata]
891	application	vnd.openxmlformats-officedocument.presentationml.notesMaster+xml	application/vnd.openxmlformats-officedocument.presentationml.notesMaster+xml	[Makoto_Murata]
892	application	vnd.openxmlformats-officedocument.presentationml.notesSlide+xml	application/vnd.openxmlformats-officedocument.presentationml.notesSlide+xml	[Makoto_Murata]
893	application	vnd.openxmlformats-officedocument.presentationml.presentation	application/vnd.openxmlformats-officedocument.presentationml.presentation	[Makoto_Murata]
894	application	vnd.openxmlformats-officedocument.presentationml.presentation.main+xml	application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml	[Makoto_Murata]
895	application	vnd.openxmlformats-officedocument.presentationml.presProps+xml	application/vnd.openxmlformats-officedocument.presentationml.presProps+xml	[Makoto_Murata]
896	application	vnd.openxmlformats-officedocument.presentationml.slide	application/vnd.openxmlformats-officedocument.presentationml.slide	[Makoto_Murata]
897	application	vnd.openxmlformats-officedocument.presentationml.slide+xml	application/vnd.openxmlformats-officedocument.presentationml.slide+xml	[Makoto_Murata]
898	application	vnd.openxmlformats-officedocument.presentationml.slideLayout+xml	application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml	[Makoto_Murata]
899	application	vnd.openxmlformats-officedocument.presentationml.slideMaster+xml	application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml	[Makoto_Murata]
900	application	vnd.openxmlformats-officedocument.presentationml.slideshow	application/vnd.openxmlformats-officedocument.presentationml.slideshow	[Makoto_Murata]
901	application	vnd.openxmlformats-officedocument.presentationml.slideshow.main+xml	application/vnd.openxmlformats-officedocument.presentationml.slideshow.main+xml	[Makoto_Murata]
902	application	vnd.openxmlformats-officedocument.presentationml.slideUpdateInfo+xml	application/vnd.openxmlformats-officedocument.presentationml.slideUpdateInfo+xml	[Makoto_Murata]
903	application	vnd.openxmlformats-officedocument.presentationml.tableStyles+xml	application/vnd.openxmlformats-officedocument.presentationml.tableStyles+xml	[Makoto_Murata]
904	application	vnd.openxmlformats-officedocument.presentationml.tags+xml	application/vnd.openxmlformats-officedocument.presentationml.tags+xml	[Makoto_Murata]
905	application	vnd.openxmlformats-officedocument.presentationml.template	application/vnd.openxmlformats-officedocument.presentationml-template	[Makoto_Murata]
906	application	vnd.openxmlformats-officedocument.presentationml.template.main+xml	application/vnd.openxmlformats-officedocument.presentationml.template.main+xml	[Makoto_Murata]
907	application	vnd.openxmlformats-officedocument.presentationml.viewProps+xml	application/vnd.openxmlformats-officedocument.presentationml.viewProps+xml	[Makoto_Murata]
1015	application	vnd.rs-274x	application/vnd.rs-274x	[Lee_Harding]
908	application	vnd.openxmlformats-officedocument.spreadsheetml.calcChain+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.calcChain+xml	[Makoto_Murata]
909	application	vnd.openxmlformats-officedocument.spreadsheetml.chartsheet+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.chartsheet+xml	[Makoto_Murata]
910	application	vnd.openxmlformats-officedocument.spreadsheetml.comments+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.comments+xml	[Makoto_Murata]
911	application	vnd.openxmlformats-officedocument.spreadsheetml.connections+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.connections+xml	[Makoto_Murata]
912	application	vnd.openxmlformats-officedocument.spreadsheetml.dialogsheet+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.dialogsheet+xml	[Makoto_Murata]
913	application	vnd.openxmlformats-officedocument.spreadsheetml.externalLink+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.externalLink+xml	[Makoto_Murata]
914	application	vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheDefinition+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheDefinition+xml	[Makoto_Murata]
915	application	vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheRecords+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheRecords+xml	[Makoto_Murata]
916	application	vnd.openxmlformats-officedocument.spreadsheetml.pivotTable+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.pivotTable+xml	[Makoto_Murata]
917	application	vnd.openxmlformats-officedocument.spreadsheetml.queryTable+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.queryTable+xml	[Makoto_Murata]
918	application	vnd.openxmlformats-officedocument.spreadsheetml.revisionHeaders+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.revisionHeaders+xml	[Makoto_Murata]
919	application	vnd.openxmlformats-officedocument.spreadsheetml.revisionLog+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.revisionLog+xml	[Makoto_Murata]
920	application	vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml	[Makoto_Murata]
921	application	vnd.openxmlformats-officedocument.spreadsheetml.sheet	application/vnd.openxmlformats-officedocument.spreadsheetml.sheet	[Makoto_Murata]
922	application	vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml	[Makoto_Murata]
923	application	vnd.openxmlformats-officedocument.spreadsheetml.sheetMetadata+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.sheetMetadata+xml	[Makoto_Murata]
924	application	vnd.openxmlformats-officedocument.spreadsheetml.styles+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml	[Makoto_Murata]
925	application	vnd.openxmlformats-officedocument.spreadsheetml.table+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.table+xml	[Makoto_Murata]
926	application	vnd.openxmlformats-officedocument.spreadsheetml.tableSingleCells+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.tableSingleCells+xml	[Makoto_Murata]
927	application	vnd.openxmlformats-officedocument.spreadsheetml.template	application/vnd.openxmlformats-officedocument.spreadsheetml-template	[Makoto_Murata]
928	application	vnd.openxmlformats-officedocument.spreadsheetml.template.main+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.template.main+xml	[Makoto_Murata]
929	application	vnd.openxmlformats-officedocument.spreadsheetml.userNames+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.userNames+xml	[Makoto_Murata]
930	application	vnd.openxmlformats-officedocument.spreadsheetml.volatileDependencies+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.volatileDependencies+xml	[Makoto_Murata]
931	application	vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml	[Makoto_Murata]
932	application	vnd.openxmlformats-officedocument.theme+xml	application/vnd.openxmlformats-officedocument.theme+xml	[Makoto_Murata]
933	application	vnd.openxmlformats-officedocument.themeOverride+xml	application/vnd.openxmlformats-officedocument.themeOverride+xml	[Makoto_Murata]
934	application	vnd.openxmlformats-officedocument.vmlDrawing	application/vnd.openxmlformats-officedocument.vmlDrawing	[Makoto_Murata]
935	application	vnd.openxmlformats-officedocument.wordprocessingml.comments+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml	[Makoto_Murata]
936	application	vnd.openxmlformats-officedocument.wordprocessingml.document	application/vnd.openxmlformats-officedocument.wordprocessingml.document	[Makoto_Murata]
937	application	vnd.openxmlformats-officedocument.wordprocessingml.document.glossary+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.document.glossary+xml	[Makoto_Murata]
938	application	vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml	[Makoto_Murata]
939	application	vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml	[Makoto_Murata]
940	application	vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml	[Makoto_Murata]
941	application	vnd.openxmlformats-officedocument.wordprocessingml.footer+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml	[Makoto_Murata]
942	application	vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml	[Makoto_Murata]
943	application	vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml	[Makoto_Murata]
944	application	vnd.openxmlformats-officedocument.wordprocessingml.settings+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml	[Makoto_Murata]
945	application	vnd.openxmlformats-officedocument.wordprocessingml.styles+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml	[Makoto_Murata]
946	application	vnd.openxmlformats-officedocument.wordprocessingml.template	application/vnd.openxmlformats-officedocument.wordprocessingml-template	[Makoto_Murata]
947	application	vnd.openxmlformats-officedocument.wordprocessingml.template.main+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.template.main+xml	[Makoto_Murata]
1016	application	vnd.ruckus.download	application/vnd.ruckus.download	[Jerry_Harris]
948	application	vnd.openxmlformats-officedocument.wordprocessingml.webSettings+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.webSettings+xml	[Makoto_Murata]
949	application	vnd.openxmlformats-package.core-properties+xml	application/vnd.openxmlformats-package.core-properties+xml	[Makoto_Murata]
950	application	vnd.openxmlformats-package.digital-signature-xmlsignature+xml	application/vnd.openxmlformats-package.digital-signature-xmlsignature+xml	[Makoto_Murata]
951	application	vnd.openxmlformats-package.relationships+xml	application/vnd.openxmlformats-package.relationships+xml	[Makoto_Murata]
952	application	vnd.oracle.resource+json	application/vnd.oracle.resource+json	[Ning_Dong]
953	application	vnd.orange.indata	application/vnd.orange.indata	[CHATRAS_Bruno]
954	application	vnd.osa.netdeploy	application/vnd.osa.netdeploy	[Steven_Klos]
955	application	vnd.osgeo.mapguide.package	application/vnd.osgeo.mapguide.package	[Jason_Birch]
956	application	vnd.osgi.bundle	application/vnd.osgi.bundle	[Peter_Kriens]
957	application	vnd.osgi.dp	application/vnd.osgi.dp	[Peter_Kriens]
958	application	vnd.osgi.subsystem	application/vnd.osgi.subsystem	[Peter_Kriens]
959	application	vnd.otps.ct-kip+xml	application/vnd.otps.ct-kip+xml	[Magnus_Nystrom]
960	application	vnd.oxli.countgraph	application/vnd.oxli.countgraph	[C._Titus_Brown]
961	application	vnd.pagerduty+json	application/vnd.pagerduty+json	[Steve_Rice]
962	application	vnd.palm	application/vnd.palm	[Gavin_Peacock]
963	application	vnd.panoply	application/vnd.panoply	[Natarajan_Balasundara]
964	application	vnd.paos.xml	application/vnd.paos+xml	[John_Kemp]
965	application	vnd.pawaafile	application/vnd.pawaafile	[Prakash_Baskaran]
966	application	vnd.pcos	application/vnd.pcos	[Slawomir_Lisznianski]
967	application	vnd.pg.format	application/vnd.pg.format	[April_Gandert]
968	application	vnd.pg.osasli	application/vnd.pg.osasli	[April_Gandert]
969	application	vnd.piaccess.application-licence	application/vnd.piaccess.application-licence	[Lucas_Maneos]
970	application	vnd.picsel	application/vnd.picsel	[Giuseppe_Naccarato]
971	application	vnd.pmi.widget	application/vnd.pmi.widget	[Rhys_Lewis]
972	application	vnd.poc.group-advertisement+xml	application/vnd.poc.group-advertisement+xml	[Sean_Kelley][OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
973	application	vnd.pocketlearn	application/vnd.pocketlearn	[Jorge_Pando]
974	application	vnd.powerbuilder6	application/vnd.powerbuilder6	[David_Guy]
975	application	vnd.powerbuilder6-s	application/vnd.powerbuilder6-s	[David_Guy]
976	application	vnd.powerbuilder7	application/vnd.powerbuilder7	[Reed_Shilts]
977	application	vnd.powerbuilder75	application/vnd.powerbuilder75	[Reed_Shilts]
978	application	vnd.powerbuilder75-s	application/vnd.powerbuilder75-s	[Reed_Shilts]
979	application	vnd.powerbuilder7-s	application/vnd.powerbuilder7-s	[Reed_Shilts]
980	application	vnd.preminet	application/vnd.preminet	[Juoko_Tenhunen]
981	application	vnd.previewsystems.box	application/vnd.previewsystems.box	[Roman_Smolgovsky]
982	application	vnd.proteus.magazine	application/vnd.proteus.magazine	[Pete_Hoch]
983	application	vnd.publishare-delta-tree	application/vnd.publishare-delta-tree	[Oren_Ben-Kiki]
984	application	vnd.pvi.ptid1	application/vnd.pvi.ptid1	[Charles_P._Lamb]
985	application	vnd.pwg-multiplexed	application/vnd.pwg-multiplexed	[RFC3391]
986	application	vnd.pwg-xhtml-print+xml	application/vnd.pwg-xhtml-print+xml	[Don_Wright]
987	application	vnd.qualcomm.brew-app-res	application/vnd.qualcomm.brew-app-res	[Glenn_Forrester]
988	application	vnd.quarantainenet	application/vnd.quarantainenet	[Casper_Joost_Eyckelhof]
989	application	vnd.Quark.QuarkXPress	application/vnd.Quark.QuarkXPress	[Hannes_Scheidler]
990	application	vnd.quobject-quoxdocument	application/vnd.quobject-quoxdocument	[Matthias_Ludwig]
991	application	vnd.radisys.moml+xml	application/vnd.radisys.moml+xml	[RFC5707]
992	application	vnd.radisys.msml-audit-conf+xml	application/vnd.radisys.msml-audit-conf+xml	[RFC5707]
993	application	vnd.radisys.msml-audit-conn+xml	application/vnd.radisys.msml-audit-conn+xml	[RFC5707]
994	application	vnd.radisys.msml-audit-dialog+xml	application/vnd.radisys.msml-audit-dialog+xml	[RFC5707]
995	application	vnd.radisys.msml-audit-stream+xml	application/vnd.radisys.msml-audit-stream+xml	[RFC5707]
996	application	vnd.radisys.msml-audit+xml	application/vnd.radisys.msml-audit+xml	[RFC5707]
997	application	vnd.radisys.msml-conf+xml	application/vnd.radisys.msml-conf+xml	[RFC5707]
998	application	vnd.radisys.msml-dialog-base+xml	application/vnd.radisys.msml-dialog-base+xml	[RFC5707]
999	application	vnd.radisys.msml-dialog-fax-detect+xml	application/vnd.radisys.msml-dialog-fax-detect+xml	[RFC5707]
1000	application	vnd.radisys.msml-dialog-fax-sendrecv+xml	application/vnd.radisys.msml-dialog-fax-sendrecv+xml	[RFC5707]
1001	application	vnd.radisys.msml-dialog-group+xml	application/vnd.radisys.msml-dialog-group+xml	[RFC5707]
1002	application	vnd.radisys.msml-dialog-speech+xml	application/vnd.radisys.msml-dialog-speech+xml	[RFC5707]
1003	application	vnd.radisys.msml-dialog-transform+xml	application/vnd.radisys.msml-dialog-transform+xml	[RFC5707]
1004	application	vnd.radisys.msml-dialog+xml	application/vnd.radisys.msml-dialog+xml	[RFC5707]
1005	application	vnd.radisys.msml+xml	application/vnd.radisys.msml+xml	[RFC5707]
1006	application	vnd.rainstor.data	application/vnd.rainstor.data	[Kevin_Crook]
1007	application	vnd.rapid	application/vnd.rapid	[Etay_Szekely]
1008	application	vnd.rar	application/vnd.rar	[Kim_Scarborough]
1009	application	vnd.realvnc.bed	application/vnd.realvnc.bed	[Nick_Reeves]
1010	application	vnd.recordare.musicxml	application/vnd.recordare.musicxml	[Michael_Good]
1011	application	vnd.recordare.musicxml+xml	application/vnd.recordare.musicxml+xml	[Michael_Good]
1012	application	vnd.RenLearn.rlprint	application/vnd.renlearn.rlprint	[James_Wick]
1013	application	vnd.rig.cryptonote	application/vnd.rig.cryptonote	[Ken_Jibiki]
1017	application	vnd.s3sms	application/vnd.s3sms	[Lauri_Tarkkala]
1018	application	vnd.sailingtracker.track	application/vnd.sailingtracker.track	[Heikki_Vesalainen]
1019	application	vnd.sbm.cid	application/vnd.sbm.cid	[Shinji_Kusakari]
1020	application	vnd.sbm.mid2	application/vnd.sbm.mid2	[Masanori_Murai]
1021	application	vnd.scribus	application/vnd.scribus	[Craig_Bradney]
1022	application	vnd.sealed.3df	application/vnd.sealed.3df	[John_Kwan]
1023	application	vnd.sealed.csf	application/vnd.sealed.csf	[John_Kwan]
1024	application	vnd.sealed.doc	application/vnd.sealed-doc	[David_Petersen]
1025	application	vnd.sealed.eml	application/vnd.sealed-eml	[David_Petersen]
1026	application	vnd.sealed.mht	application/vnd.sealed-mht	[David_Petersen]
1027	application	vnd.sealed.net	application/vnd.sealed.net	[Martin_Lambert]
1028	application	vnd.sealed.ppt	application/vnd.sealed-ppt	[David_Petersen]
1029	application	vnd.sealed.tiff	application/vnd.sealed-tiff	[John_Kwan][Martin_Lambert]
1030	application	vnd.sealed.xls	application/vnd.sealed-xls	[David_Petersen]
1031	application	vnd.sealedmedia.softseal.html	application/vnd.sealedmedia.softseal-html	[David_Petersen]
1032	application	vnd.sealedmedia.softseal.pdf	application/vnd.sealedmedia.softseal-pdf	[David_Petersen]
1033	application	vnd.seemail	application/vnd.seemail	[Steve_Webb]
1034	application	vnd.sema	application/vnd-sema	[Anders_Hansson]
1035	application	vnd.semd	application/vnd.semd	[Anders_Hansson]
1036	application	vnd.semf	application/vnd.semf	[Anders_Hansson]
1037	application	vnd.shana.informed.formdata	application/vnd.shana.informed.formdata	[Guy_Selzler]
1038	application	vnd.shana.informed.formtemplate	application/vnd.shana.informed.formtemplate	[Guy_Selzler]
1039	application	vnd.shana.informed.interchange	application/vnd.shana.informed.interchange	[Guy_Selzler]
1040	application	vnd.shana.informed.package	application/vnd.shana.informed.package	[Guy_Selzler]
1041	application	vnd.SimTech-MindMapper	application/vnd.SimTech-MindMapper	[Patrick_Koh]
1042	application	vnd.siren+json	application/vnd.siren+json	[Kevin_Swiber]
1043	application	vnd.smaf	application/vnd.smaf	[Hiroaki_Takahashi]
1044	application	vnd.smart.notebook	application/vnd.smart.notebook	[Jonathan_Neitz]
1045	application	vnd.smart.teacher	application/vnd.smart.teacher	[Michael_Boyle]
1046	application	vnd.software602.filler.form+xml	application/vnd.software602.filler.form+xml	[Jakub_Hytka][Martin_Vondrous]
1047	application	vnd.software602.filler.form-xml-zip	application/vnd.software602.filler.form-xml-zip	[Jakub_Hytka][Martin_Vondrous]
1048	application	vnd.solent.sdkm+xml	application/vnd.solent.sdkm+xml	[Cliff_Gauntlett]
1049	application	vnd.spotfire.dxp	application/vnd.spotfire.dxp	[Stefan_Jernberg]
1050	application	vnd.spotfire.sfs	application/vnd.spotfire.sfs	[Stefan_Jernberg]
1051	application	vnd.sss-cod	application/vnd.sss-cod	[Asang_Dani]
1052	application	vnd.sss-dtf	application/vnd.sss-dtf	[Eric_Bruno]
1053	application	vnd.sss-ntf	application/vnd.sss-ntf	[Eric_Bruno]
1054	application	vnd.stepmania.package	application/vnd.stepmania.package	[Henrik_Andersson]
1055	application	vnd.stepmania.stepchart	application/vnd.stepmania.stepchart	[Henrik_Andersson]
1056	application	vnd.street-stream	application/vnd.street-stream	[Glenn_Levitt]
1057	application	vnd.sun.wadl+xml	application/vnd.sun.wadl+xml	[Marc_Hadley]
1058	application	vnd.sus-calendar	application/vnd.sus-calendar	[Jonathan_Niedfeldt]
1059	application	vnd.svd	application/vnd.svd	[Scott_Becker]
1060	application	vnd.swiftview-ics	application/vnd.swiftview-ics	[Glenn_Widener]
1061	application	vnd.syncml.dm.notification	application/vnd.syncml.dm.notification	[Peter_Thompson][OMA-DM_Work_Group]
1062	application	vnd.syncml.dmddf+xml	application/vnd.syncml.dmddf+xml	[OMA-DM_Work_Group]
1063	application	vnd.syncml.dmtnds+wbxml	application/vnd.syncml.dmtnds+wbxml	[OMA-DM_Work_Group]
1064	application	vnd.syncml.dmtnds+xml	application/vnd.syncml.dmtnds+xml	[OMA-DM_Work_Group]
1065	application	vnd.syncml.dmddf+wbxml	application/vnd.syncml.dmddf+wbxml	[OMA-DM_Work_Group]
1066	application	vnd.syncml.dm+wbxml	application/vnd.syncml.dm+wbxml	[OMA-DM_Work_Group]
1067	application	vnd.syncml.dm+xml	application/vnd.syncml.dm+xml	[Bindu_Rama_Rao][OMA-DM_Work_Group]
1068	application	vnd.syncml.ds.notification	application/vnd.syncml.ds.notification	[OMA_Data_Synchronization_Working_Group]
1069	application	vnd.syncml+xml	application/vnd.syncml+xml	[OMA_Data_Synchronization_Working_Group]
1070	application	vnd.tao.intent-module-archive	application/vnd.tao.intent-module-archive	[Daniel_Shelton]
1071	application	vnd.tcpdump.pcap	application/vnd.tcpdump.pcap	[Guy_Harris][Glen_Turner]
1072	application	vnd.tml	application/vnd.tml	[Joey_Smith]
1073	application	vnd.tmd.mediaflex.api+xml	application/vnd.tmd.mediaflex.api+xml	[Alex_Sibilev]
1074	application	vnd.tmobile-livetv	application/vnd.tmobile-livetv	[Nicolas_Helin]
1075	application	vnd.tri.onesource	application/vnd.tri.onesource	[Rick_Rupp]
1076	application	vnd.trid.tpt	application/vnd.trid.tpt	[Frank_Cusack]
1077	application	vnd.triscape.mxs	application/vnd.triscape.mxs	[Steven_Simonoff]
1078	application	vnd.trueapp	application/vnd.trueapp	[J._Scott_Hepler]
1079	application	vnd.truedoc	application/vnd.truedoc	[Brad_Chase]
1080	application	vnd.ubisoft.webplayer	application/vnd.ubisoft.webplayer	[Martin_Talbot]
1081	application	vnd.ufdl	application/vnd.ufdl	[Dave_Manning]
1082	application	vnd.uiq.theme	application/vnd.uiq.theme	[Tim_Ocock]
1083	application	vnd.umajin	application/vnd.umajin	[Jamie_Riden]
1084	application	vnd.unity	application/vnd.unity	[Unity3d]
1085	application	vnd.uoml+xml	application/vnd.uoml+xml	[Arne_Gerdes]
1086	application	vnd.uplanet.alert	application/vnd.uplanet.alert	[Bruce_Martin]
1087	application	vnd.uplanet.alert-wbxml	application/vnd.uplanet.alert-wbxml	[Bruce_Martin]
1088	application	vnd.uplanet.bearer-choice	application/vnd.uplanet.bearer-choice	[Bruce_Martin]
1089	application	vnd.uplanet.bearer-choice-wbxml	application/vnd.uplanet.bearer-choice-wbxml	[Bruce_Martin]
1090	application	vnd.uplanet.cacheop	application/vnd.uplanet.cacheop	[Bruce_Martin]
1091	application	vnd.uplanet.cacheop-wbxml	application/vnd.uplanet.cacheop-wbxml	[Bruce_Martin]
1092	application	vnd.uplanet.channel	application/vnd.uplanet.channel	[Bruce_Martin]
1093	application	vnd.uplanet.channel-wbxml	application/vnd.uplanet.channel-wbxml	[Bruce_Martin]
1094	application	vnd.uplanet.list	application/vnd.uplanet.list	[Bruce_Martin]
1095	application	vnd.uplanet.listcmd	application/vnd.uplanet.listcmd	[Bruce_Martin]
1096	application	vnd.uplanet.listcmd-wbxml	application/vnd.uplanet.listcmd-wbxml	[Bruce_Martin]
1097	application	vnd.uplanet.list-wbxml	application/vnd.uplanet.list-wbxml	[Bruce_Martin]
1098	application	vnd.uri-map	application/vnd.uri-map	[Sebastian_Baer]
1099	application	vnd.uplanet.signal	application/vnd.uplanet.signal	[Bruce_Martin]
1100	application	vnd.valve.source.material	application/vnd.valve.source.material	[Henrik_Andersson]
1101	application	vnd.vcx	application/vnd.vcx	[Taisuke_Sugimoto]
1102	application	vnd.vd-study	application/vnd.vd-study	[Luc_Rogge]
1103	application	vnd.vectorworks	application/vnd.vectorworks	[Lyndsey_Ferguson][Biplab_Sarkar]
1104	application	vnd.vel+json	application/vnd.vel+json	[James_Wigger]
1105	application	vnd.verimatrix.vcas	application/vnd.verimatrix.vcas	[Petr_Peterka]
1106	application	vnd.vidsoft.vidconference	application/vnd.vidsoft.vidconference	[Robert_Hess]
1107	application	vnd.visio	application/vnd.visio	[Troy_Sandal]
1108	application	vnd.visionary	application/vnd.visionary	[Gayatri_Aravindakumar]
1109	application	vnd.vividence.scriptfile	application/vnd.vividence.scriptfile	[Mark_Risher]
1110	application	vnd.vsf	application/vnd.vsf	[Delton_Rowe]
1111	application	vnd.wap.sic	application/vnd.wap.sic	[WAP-Forum]
1112	application	vnd.wap.slc	application/vnd.wap-slc	[WAP-Forum]
1113	application	vnd.wap.wbxml	application/vnd.wap-wbxml	[Peter_Stark]
1114	application	vnd.wap.wmlc	application/vnd-wap-wmlc	[Peter_Stark]
1115	application	vnd.wap.wmlscriptc	application/vnd.wap.wmlscriptc	[Peter_Stark]
1116	application	vnd.webturbo	application/vnd.webturbo	[Yaser_Rehem]
1117	application	vnd.wfa.p2p	application/vnd.wfa.p2p	[Mick_Conley]
1118	application	vnd.wfa.wsc	application/vnd.wfa.wsc	[Wi-Fi_Alliance]
1119	application	vnd.windows.devicepairing	application/vnd.windows.devicepairing	[Priya_Dandawate]
1120	application	vnd.wmc	application/vnd.wmc	[Thomas_Kjornes]
1121	application	vnd.wmf.bootstrap	application/vnd.wmf.bootstrap	[Thinh_Nguyenphu][Prakash_Iyer]
1122	application	vnd.wolfram.mathematica	application/vnd.wolfram.mathematica	[Wolfram]
1123	application	vnd.wolfram.mathematica.package	application/vnd.wolfram.mathematica.package	[Wolfram]
1124	application	vnd.wolfram.player	application/vnd.wolfram.player	[Wolfram]
1125	application	vnd.wordperfect	application/vnd.wordperfect	[Kim_Scarborough]
1126	application	vnd.wqd	application/vnd.wqd	[Jan_Bostrom]
1127	application	vnd.wrq-hp3000-labelled	application/vnd.wrq-hp3000-labelled	[Chris_Bartram]
1128	application	vnd.wt.stf	application/vnd.wt.stf	[Bill_Wohler]
1129	application	vnd.wv.csp+xml	application/vnd.wv.csp+xml	[John_Ingi_Ingimundarson]
1130	application	vnd.wv.csp+wbxml	application/vnd.wv.csp+wbxml	[Matti_Salmi]
1131	application	vnd.wv.ssp+xml	application/vnd.wv.ssp+xml	[John_Ingi_Ingimundarson]
1132	application	vnd.xacml+json	application/vnd.xacml+json	[David_Brossard]
1133	application	vnd.xara	application/vnd.xara	[David_Matthewman]
1134	application	vnd.xfdl	application/vnd.xfdl	[Dave_Manning]
1135	application	vnd.xfdl.webform	application/vnd.xfdl.webform	[Michael_Mansell]
1136	application	vnd.xmi+xml	application/vnd.xmi+xml	[Fred_Waskiewicz]
1137	application	vnd.xmpie.cpkg	application/vnd.xmpie.cpkg	[Reuven_Sherwin]
1138	application	vnd.xmpie.dpkg	application/vnd.xmpie.dpkg	[Reuven_Sherwin]
1139	application	vnd.xmpie.plan	application/vnd.xmpie.plan	[Reuven_Sherwin]
1140	application	vnd.xmpie.ppkg	application/vnd.xmpie.ppkg	[Reuven_Sherwin]
1141	application	vnd.xmpie.xlim	application/vnd.xmpie.xlim	[Reuven_Sherwin]
1142	application	vnd.yamaha.hv-dic	application/vnd.yamaha.hv-dic	[Tomohiro_Yamamoto]
1143	application	vnd.yamaha.hv-script	application/vnd.yamaha.hv-script	[Tomohiro_Yamamoto]
1144	application	vnd.yamaha.hv-voice	application/vnd.yamaha.hv-voice	[Tomohiro_Yamamoto]
1145	application	vnd.yamaha.openscoreformat.osfpvg+xml	application/vnd.yamaha.openscoreformat.osfpvg+xml	[Mark_Olleson]
1146	application	vnd.yamaha.openscoreformat	application/vnd.yamaha.openscoreformat	[Mark_Olleson]
1147	application	vnd.yamaha.remote-setup	application/vnd.yamaha.remote-setup	[Takehiro_Sukizaki]
1148	application	vnd.yamaha.smaf-audio	application/vnd.yamaha.smaf-audio	[Keiichi_Shinoda]
1149	application	vnd.yamaha.smaf-phrase	application/vnd.yamaha.smaf-phrase	[Keiichi_Shinoda]
1150	application	vnd.yamaha.through-ngn	application/vnd.yamaha.through-ngn	[Takehiro_Sukizaki]
1151	application	vnd.yamaha.tunnel-udpencap	application/vnd.yamaha.tunnel-udpencap	[Takehiro_Sukizaki]
1152	application	vnd.yaoweme	application/vnd.yaoweme	[Jens_Jorgensen]
1153	application	vnd.yellowriver-custom-menu	application/vnd.yellowriver-custom-menu	[Mr._Yellow]
1154	application	vnd.zul	application/vnd.zul	[Rene_Grothmann]
1155	application	vnd.zzazz.deck+xml	application/vnd.zzazz.deck+xml	[Micheal_Hewett]
1156	application	voicexml+xml	application/voicexml+xml	[RFC4267]
1157	application	vq-rtcpxr	application/vq-rtcpxr	[RFC6035]
1158	application	watcherinfo+xml	application/watcherinfo+xml	[RFC3858]
1159	application	whoispp-query	application/whoispp-query	[RFC2957]
1160	application	whoispp-response	application/whoispp-response	[RFC2958]
1161	application	widget		[W3C][Steven_Pemberton][ISO/IEC 19757-2:2003/FDAM-1]
1163	application	wordperfect5.1	application/wordperfect5.1	[Paul_Lindner]
1164	application	wsdl+xml	application/wsdl+xml	[W3C]
1165	application	wspolicy+xml	application/wspolicy+xml	[W3C]
1166	application	x-www-form-urlencoded	application/x-www-form-urlencoded	[W3C][Robin_Berjon]
1167	application	x400-bp	application/x400-bp	[RFC1494]
1168	application	xacml+xml	application/xacml+xml	[RFC7061]
1169	application	xcap-att+xml	application/xcap-att+xml	[RFC4825]
1170	application	xcap-caps+xml	application/xcap-caps+xml	[RFC4825]
1171	application	xcap-diff+xml	application/xcap-diff+xml	[RFC5874]
1172	application	xcap-el+xml	application/xcap-el+xml	[RFC4825]
1173	application	xcap-error+xml	application/xcap-error+xml	[RFC4825]
1174	application	xcap-ns+xml	application/xcap-ns+xml	[RFC4825]
1175	application	xcon-conference-info-diff+xml	application/xcon-conference-info-diff+xml	[RFC6502]
1176	application	xcon-conference-info+xml	application/xcon-conference-info+xml	[RFC6502]
1177	application	xenc+xml	application/xenc+xml	[Joseph_Reagle][XENC_Working_Group]
1178	application	xhtml+xml	application/xhtml+xml	[W3C][Robin_Berjon]
1179	application	xml	application/xml	[RFC7303]
1180	application	xml-dtd	application/xml-dtd	[RFC7303]
1181	application	xml-external-parsed-entity	application/xml-external-parsed-entity	[RFC7303]
1182	application	xml-patch+xml	application/xml-patch+xml	[RFC7351]
1183	application	xmpp+xml	application/xmpp+xml	[RFC3923]
1184	application	xop+xml	application/xop+xml	[Mark_Nottingham]
1185	application	xslt+xml		[W3C][http://www.w3.org/TR/2007/REC-xslt20-20070123/#media-type-registration]
1186	application	xv+xml	application/xv+xml	[RFC4374]
1187	application	yang	application/yang	[RFC6020]
1188	application	yin+xml	application/yin+xml	[RFC6020]
1189	application	zip	application/zip	[Paul_Lindner]
1190	application	zlib	application/zlib	[RFC6713]
\.


--
-- Data for Name: documentmanagement; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.documentmanagement (id, contractingprocess_id, origin, document, instance_id, type, register_date, error) FROM stdin;
\.


--
-- Data for Name: documenttype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.documenttype (id, category, code, title, title_esp, description, source, stage) FROM stdin;
1	intermediate	hearingNotice	Public Hearing Notice	Aviso de audiencia pública	Details of any public hearings that took place as part of the planning for this procurement.		1
2	advanced	feasibilityStudy	Feasibility study	Estudio de factibilidad			1
3	advanced	assetAndLiabilityAssessment	Assesment of government’s assets and liabilities	Evaluación de los activos y responsabilidades del gobierno			1
4	advanced	environmentalImpact	Environmental Impact	Estudios de impacto urbano y ambiental			1
5	advanced	needsAssessment	Needs Assessment	Justificación de la contratación			1
6	advanced	projectPlan	Project plan	Plan de proyecto			1
7	basic	procurementPlan	Procurement Plan	Proyecto de convocatoria			1
8	intermediate	clarifications	Clarifications to bidders questions	Acta de junta de aclaraciones	Including replies to issues raised in pre-bid conferences.		2
9	basic	technicalSpecifications	Technical Specifications	Anexo técnico	Detailed technical information about goods or services to be provided.		2
10	basic	biddingDocuments	Bidding Documents	Anexos de la convocatoria	Information for potential suppliers, describing the goals of the contract (e.g. goods and services to be procured) and the bidding process.		2
11	advanced	riskProvisions	Provisions for management of risks and liabilities	Cláusulas de riesgos y responsabilidades			2
12	advanced	conflictOfInterest	conflicts of interest uncovered	Conflicto de intereses			2
13	intermediate	eligibilityCriteria	Eligibility Criteria	Criterios de elegibilidad	Detailed documents about the eligibility of bidders.		2
14	basic	evaluationCriteria	Evaluation Criteria	Criterios de evaluación	Information about how bids will be evaluated.		2
15	intermediate	shortlistedFirms	Shortlisted Firms	Empresas preseleccionadas			2
16	advanced	billOfQuantity	Bill Of Quantity	Especificación de cantidades			2
17	advanced	bidders	Information on bidders	Información del licitante	Information on bidders or participants,their validation documents and any procedural exemptions for which they qualify		2
18	advanced	debarments	debarments issued	Inhabilitaciones			2
19	advanced	winningBid	Winning Bid	Proposición ganadora			3
20	advanced	complaints	Complaints and decisions	Quejas y aclaraciones			3
21	intermediate	evaluationReports	Evaluation report	Reporte de resultado de la evaluación	Report on the evaluation of the bids and the application of the evaluation criteria, including the justification fo the award		3
22	intermediate	contractArrangements	Arrangements for ending contract	Acuerdos de terminación del contrato			4
23	intermediate	contractSchedule	Schedules and milestones	Anexo del contrato			4
24	advanced	contractAnnexe	Contract Annexe	Anexos del Contrato			4
25	basic	contractNotice	Contract Notice	Datos relevantes del contrato	The formal notice that gives details of a contract being signed and valid to start implementation. This may be a link to a downloadable document		4
26	advanced	contractGuarantees	Guarantees	Garantías del contrato			4
27	advanced	subContract	Subcontracts	Subcontratos	A document detailing subcontracts,  the subcontract itself or a linked OCDS document describing a subcontract.		4
28	basic	contractText	Contract Text	Texto del contrato			0
29	intermediate	finalAudit	Final Audit	Conclusión de la auditoría			5
30	intermediate	financialProgressReport	Financial progress reports	Informe de avance financiero	Dates and amounts of stage payments made (against total amount) and the source of those payments, including cost overruns if any. Structured versions of this data can be provided through transactions.		5
31	intermediate	physicalProgressReport	Physical progress reports	Informe de avance físico	A report on the status of implementation, usually against key milestones.		5
32	intermediate	marketStudies		Resultado de la investigación de mercado			1
33	intermediate	request		Requisición			1
34	intermediate	tenderNotice		Convocatoria o invitación			2
35	intermediate	unsuccessfulProcedureNotice		Acta de fallo (desierto)			3
36	intermediate	awardNotice		Notificación de la adjudicación			3
37	intermediate	contractSigned		Contrato			4
38	intermediate	completionCertificate		Dictamen de cumplimiento			5
39	advanced	submissionDocuments	Submission Documents	Documentos de envío	Documentación enviada por un oferente como parte de su propuesta.		3
40	advanced	awardDeferral	Award Deferral	Acta de diferimiento al fallo	Documento formal que modifica la fecha en la que se celebrará el fallo a un momento posterior al que estaba previsto en la convocatoria.		3
41	advanced	cancellationDetails	Cancellation Details	Detalles de cancelación	Documentación de los arreglos, o razones, para la cancelación de un proceso de contratación, adjudicación o contrato específico.		3
42	basic	openingOfProposals	Opening Of Proposals	Documento en donde consta la presentación de las propuestas	Documento en donde consta la presentación de las propuestas		2
43	basic	settlement	Settlement	Finiquito	Documento elaborado una vez concluídos los trabajos derivados de un contrato celebrado con una dependencia o entidad del Estado. En este se hará constar los créditos a favor y en contra que resulten para cada una de las partes involucradas, tales son la dependecia y el contratista.		5
44	basic	contractAmendment	Contract Amendment	Convenio modificatorio	Documento en el que se detallan las modificaciones realizadas a las condiciones originales del contrato.		4
45	basic	physicalReception	Physical Reception	Acta de recepción de los trabajos ejecutados u homóloga en su caso	Documento elaborado por la entidad o dependecia en el que se procede a la recepción física  los trabajos realizados. Este documento se elabora dentro de los 15 días naturales siguientes a la debida terminación de los mismos, previa presentación de la garantía de defectos, vicios ocultos y de cualquier otra responsabilidad.		5
46	basic	procurementMethodAuthorization	Procurement Method Authorization	Autorización del ejercicio de la opción	Autorización escrita del titular de la dependencia o entidad, o aquel servidor público en quién éste delegue dicha atribución, así como del dictamen del área respectiva, de que no se cuenta con personal capacitado o disponible para su realización.		2
47	basic	suspensionNotice	Suspension Notice	Comunicado de la suspensión	Documento  en el que las dependencias y entidades podrán suspender temporalmente, en todo o en parte, los trabajos contratados por cualquier causa justificada. Los titulares de las dependencias y los órganos de gobierno de las entidades designarán a los servidores públicos que podrán ordenar la suspensión y determinar, en su caso, la temporalidad de ésta, la que no podrá ser indefinida.		4
48	advanced	transferReport	Transfer Report	Reporte de transferencias	Documento de reporte de transferencias bancarias.		5
\.


--
-- Data for Name: gdmx_dictionary; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.gdmx_dictionary (id, document, variable, tablename, field, parent, type, index, classification, catalog, catalog_field, storeprocedure) FROM stdin;
\.


--
-- Data for Name: gdmx_document; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.gdmx_document (id, name, stage, type, tablename, identifier) FROM stdin;
\.


--
-- Data for Name: guarantees; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.guarantees (id, contractingprocess_id, contract_id, guarantee_id, type, date, obligations, value, guarantor, guaranteeperiod_startdate, guaranteeperiod_enddate, currency) FROM stdin;
\.


--
-- Data for Name: implementation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.implementation (id, contractingprocess_id, contract_id, status, datelastupdate) FROM stdin;
\.


--
-- Data for Name: implementationdocuments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.implementationdocuments (id, contractingprocess_id, contract_id, implementation_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: implementationmilestone; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.implementationmilestone (id, contractingprocess_id, contract_id, implementation_id, milestoneid, title, description, duedate, date_modified, status, type) FROM stdin;
\.


--
-- Data for Name: implementationmilestonedocuments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.implementationmilestonedocuments (id, contractingprocess_id, contract_id, implementation_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: implementationstatus; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.implementationstatus (id, code, title, title_esp, description) FROM stdin;
1	None	none	Ninguno	
2	planning	planning	En planeación	
3	ongoing	ongoing	En progreso	
4	concluded	concluded	En finiquito	
\.


--
-- Data for Name: implementationtransactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.implementationtransactions (id, contractingprocess_id, contract_id, implementation_id, transactionid, source, implementation_date, value_amount, value_currency, payment_method, uri, payer_name, payer_id, payee_name, payee_id, value_amountnet) FROM stdin;
\.


--
-- Data for Name: item; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.item (id, classificationid, description, unit) FROM stdin;
1	2000	Materiales y suministros	
2	2100	Materiales de administracion, emision de documentos y articulos oficiales	
3	2110	Materiales, utiles y equipos menores de oficina	
4	21101	Materiales y utiles de oficina	
5	21100001	Abrecartas	Pieza
6	21100002	Achaparrador de letras	Pieza
7	21100003	Acrileta	Pieza
8	21100004	Afilaminas	Pieza
9	21100005	Agenda	Pieza
10	21100006	Aguja para alacran	Pieza
11	21100007	Alargadera	Pieza
12	21100008	Album	Pieza
13	21100009	Alfiler para señalizacion en mapa	Pieza
14	21100010	Aparato automatico para fijar chinches	Pieza
15	21100011	Apoyabrazos	Pieza
16	21100012	Arbol de navidad	Pieza
17	21100013	Arenero	Pieza
18	21100014	Atril mecanografico	Pieza
19	21100015	Barra listero (porta listas o barra rotafolio)	Pieza
20	21100016	Barril punto rapidografo	Pieza
21	21100017	Base agenda	Pieza
22	21100018	Base calendario	Pieza
23	21100019	Base cenicero (pie)	Pieza
24	21100020	Base cortes material dibujo	Pieza
25	21100021	Base planos	Pieza
26	21100022	Bastidor	Pieza
27	21100023	Bicolor	Pieza
28	21100024	Bigote (cepillo para dibujante)	Pieza
29	21100025	Blocks	Pieza
30	21100026	Boligrafos	Pieza
31	21100027	Bolsa filtro maquina reproductora	Pieza
32	21100028	Bolsa libreta	Pieza
33	21100029	Bolsas cartera	Pieza
34	21100030	Borrador	Pieza
35	21100031	Borrador para pizarron	Pieza
36	21100032	Broches para folder	Pieza
37	21100033	Brujula de plastico	Pieza
38	21100034	Cajas de carton (corrugado, liso y plegadizo)	Pieza
39	21100035	Calavera borrador	Pieza
40	21100036	Calendario de escritorio	Pieza
41	21100037	Caligrafo	Pieza
42	21100038	Canastilla correspondencia	Pieza
43	21100039	Cangrejo	Pieza
44	21100040	Carpeta escritorio	Pieza
45	21100041	Carpetas para archivo	Pieza
46	21100042	Carpetas para expediente medico	Pieza
47	21100043	Carton	Pieza
48	21100044	Cartoncillo	Pieza
49	21100045	Cartoncillo caple	Pieza
50	21100046	Cartoncillo cuplex	Pieza
51	21100047	Cartoncillo manila	Pieza
52	21100048	Cartulina	Pieza
53	21100049	Cartulina ilustracion	Pieza
54	21100050	Cartulina manila	Pieza
55	21100051	Cartulina marquilla	Pieza
56	21100052	Cartulina master	Pieza
57	21100053	Cartulina offset	Pieza
58	21100054	Celotex	Pieza
59	21100055	Cenicero	Pieza
60	21100056	Cesto basura	Pieza
61	21100057	Cesto de plastico	Pieza
62	21100058	Charola (estante)	Pieza
63	21100059	Charola de poliestireno	Pieza
64	21100060	Charola papelera	Pieza
65	21100061	Chinche	Pieza
66	21100062	Cigarrera	Pieza
67	21100063	Cinta adhesiva (diurex)	Pieza
68	21100064	Cinta adhesiva canela	Pieza
69	21100065	Cinta adhesiva masking tape	Pieza
70	21100066	Cinta para coser expedientes	Pieza
71	21100067	Cinta rotulador	Pieza
72	21100068	Cintas para maquinas de oficina	Pieza
73	21100069	Clips	Pieza
74	21100070	Clips tipo mariposa	Pieza
75	21100071	Cojin de talco para dibujante canastilla aforos	Pieza
76	21100072	Cojin sello	Pieza
77	21100073	Cojin sillon	Pieza
78	21100074	Cono contabilidad archivo de cuenta	Pieza
79	21100075	Corrector estencil	Pieza
80	21100076	Corrector liquido	Pieza
81	21100077	Correctores para maquina de escribir	Pieza
82	21100078	Crayones	Pieza
83	21100079	Cuadernos	Pieza
84	21100080	Cubierta para engargolar	Pieza
85	21100081	Curvigrafo (juego de) pistolas de curvas	Pieza
86	21100082	Cutter	Pieza
87	21100083	Dedal hule	Pieza
88	21100084	Desengrapadora	Pieza
89	21100085	Despachador integrador cinta adhesiva	Pieza
90	21100086	Despachador papel	Pieza
91	21100087	Directografo	Pieza
92	21100088	Directorio telefonico para escritorio	Pieza
93	21100089	Engrapadora	Pieza
94	21100090	Entrepaño	Pieza
95	21100091	Envases de carton	Pieza
96	21100092	Escalas juego	Pieza
97	21100093	Escalimetro	Pieza
98	21100094	Escuadra	Pieza
99	21100095	Esferas para maquina de escribir	Pieza
100	21100096	Espaciador impresion	Pieza
101	21100097	Espiral plastico	Pieza
102	21100098	Esponjero	Pieza
103	21100099	Estilografo	Pieza
104	21100100	Estuche cuchilla (navaja)	Pieza
105	21100101	Estuche juego de geometria	Pieza
106	21100102	Estuche para baquetas (accesorio p/instrumento musical)	Pieza
107	21100103	Filmina	Pieza
108	21100104	Folders	Pieza
109	21100105	Foliadores	Pieza
110	21100106	Formas impresas	Pieza
111	21100107	Funda maquina	Pieza
112	21100108	Grafos	Pieza
113	21100109	Grapas	Pieza
114	21100110	Herraje metalico encuadernacion	Pieza
115	21100111	Indice alfabetico	Pieza
116	21100112	Juego dados (resellos credenciales)	Pieza
117	21100113	Juego escritorio	Pieza
118	21100114	Juego plumas dibujo	Pieza
119	21100115	Juego plumas fuente con base	Pieza
120	21100116	Lamina para bosquejo	Pieza
121	21100117	Lamina para dibujo	Pieza
122	21100118	Lamina para graficado	Pieza
123	21100119	Lamina para litografia	Pieza
124	21100120	Lamina para poster	Pieza
125	21100121	Lapices	Pieza
126	21100122	Letra film	Pieza
127	21100123	Letraset	Pieza
128	21100124	Ligas	Pieza
129	21100125	Limpia tipos	Pieza
130	21100126	Maletines	Pieza
131	21100127	Margaritas para maquina de escribir	Pieza
132	21100128	Mata moscas (manual)	Pieza
133	21100129	Mica autoadherible	Pieza
134	21100130	Mochila para reparto de correspondencia	Pieza
135	21100131	Paleta pintor	Pieza
136	21100132	Papel aereo y copia	Pieza
137	21100133	Papel bond	Pieza
138	21100134	Papel carbon	Pieza
139	21100135	Papel celofan	Pieza
140	21100136	Papel china	Pieza
141	21100137	Papel copia	Pieza
142	21100138	Papel corrugado	Pieza
143	21100139	Papel crepe	Pieza
144	21100140	Papel etiquetas engomado	Pieza
145	21100141	Papel filtro	Pieza
146	21100142	Papel kraft	Pieza
147	21100143	Papel laminas engomado	Pieza
148	21100144	Papel para dibujo	Pieza
149	21100145	Papel para envoltura	Pieza
150	21100146	Papel para fax	Pieza
151	21100147	Papel para fotocopiadora	Pieza
152	21100148	Papel rollo engomado	Pieza
153	21100149	Papel semikraft	Pieza
154	21100150	Papel tiras engomado	Pieza
155	21100151	Papelera	Pieza
156	21100152	Pegamento amarillo (cemento)	Pieza
157	21100153	Pegamento en tubo	Pieza
158	21100154	Pegamento liquido	Pieza
159	21100155	Perforadora	Pieza
160	21100156	Pichonera para separar boletos	Pieza
161	21100157	Pichonera para separar cartas	Pieza
162	21100158	Pincel	Pieza
163	21100159	Pinturas para acuarela	Pieza
164	21100160	Pinturas para oleo	Pieza
165	21100161	Pinturas pastel	Pieza
166	21100162	Pinzas de resello de credenciales	Pieza
167	21100163	Pisa papel	Pieza
168	21100164	Plantilla	Pieza
169	21100165	Plumas	Pieza
170	21100166	Plumas atomicas	Pieza
171	21100167	Plumas fuente	Pieza
172	21100169	Porta cartulinas	Pieza
173	21100170	Porta clips	Pieza
174	21100171	Porta gafetes	Pieza
175	21100172	Porta lapices	Pieza
176	21100173	Porta minas	Pieza
177	21100174	Porta tarjetas	Pieza
178	21100175	Portafolios	Pieza
179	21100176	Portalibros	Pieza
180	21100177	Portasellos	Pieza
181	21100178	Portautensilios dibujo	Pieza
182	21100179	Postes de aluminio	Pieza
183	21100180	Protector cheques	Pieza
184	21100181	Puntilla lapices	Pieza
185	21100182	Refuerzos (para perforacion en papel)	Pieza
186	21100183	Regla tres brazos	Pieza
187	21100184	Reglas de madera	Pieza
188	21100185	Reglas de metal	Pieza
189	21100186	Reglas de plastico	Pieza
190	21100187	Reglas de precision	Pieza
191	21100188	Repuesto boligrafo	Pieza
192	21100189	Rollos de papel para calculadora	Pieza
193	21100190	Rollos de papel para sumadora	Pieza
194	21100191	Rotulador (dimo)	Pieza
195	21100192	Saco correspondencia	Pieza
196	21100193	Salamandra	Pieza
197	21100194	Sello de goma	Pieza
198	21100195	Sello mecanico	Pieza
199	21100196	Señal kardex	Pieza
200	21100197	Separadores de cartulina	Pieza
201	21100198	Separadores de plastico	Pieza
202	21100199	Servilletas de papel	Pieza
203	21100200	Silla de material plastico	Pieza
204	21100201	Sobres aereos	Pieza
205	21100202	Sobres de papel	Pieza
206	21100203	Sobres impresos	Pieza
207	21100204	Sobres ordinarios	Pieza
208	21100205	Sobres postales	Pieza
209	21100206	Stencil	Pieza
210	21100207	Sujeta libros	Pieza
211	21100208	Tabla dibujo	Pieza
212	21100209	Tabla registro con clip sujetador	Pieza
213	21100210	Tajalapiz electrico ( sacapuntas electrico )	Pieza
214	21100211	Tajalapiz manual ( sacapuntas manual )	Pieza
215	21100212	Tapete	Pieza
216	21100213	Tarjetas	Pieza
217	21100214	Tarjetas catalograficas	Pieza
218	21100215	Tarjetero	Pieza
219	21100216	Tijeras para oficina	Pieza
220	21100217	Tintas para carton	Pieza
221	21100218	Tintas para dibujo	Pieza
222	21100219	Tintas para escritura	Pieza
223	21100220	Tintas para papel	Pieza
224	21100221	Tintero	Pieza
225	21100222	Tipo para letra de goma	Pieza
226	21100223	Tipo para letra de metal	Pieza
227	21100224	Tipo para letra de plastico	Pieza
228	21100225	Tirilla kardex	Pieza
229	21100226	Toallas desechables	Pieza
230	21100227	Transportador	Pieza
231	21100228	Vasos de papel	Pieza
232	21100229	Acordeon (archivador)	Pieza
233	21100230	Agarrapapel	Pieza
234	21100231	Almohadilla para sello	Pieza
235	21100232	Anillo de plastico para encuadernar	Pieza
236	21100233	Bandeja	Pieza
237	21100234	Cinta transparente cristal	Pieza
238	21100235	Cinta velcro	Pieza
239	21100236	Etileno vinil acetato (foamy)	Pieza
240	21100237	Fechador	Pieza
241	21100238	Ficheros	Pieza
242	21100239	Godete	Pieza
243	21100240	Lapiz adhesivo	Pieza
244	21100241	Lapiz borrador	Pieza
245	21100242	Marbete	Pieza
246	21100243	Marca textos	Pieza
247	21100244	Personificador	Pieza
248	21100245	Pinza	Pieza
249	21100246	Pistola	Pieza
250	21100247	Placa	Pieza
251	21100248	Plumin (plumon)	Pieza
252	21100249	Porta mica	Pieza
253	21100250	Rollo	Pieza
254	21100251	Serpentina	Pieza
255	21100252	Silicon	Pieza
256	21100253	Sumadora	Pieza
257	21100254	Tinta china	Pieza
258	21100255	Tinta para sello	Pieza
259	21100257	Tarjetas de control de informacion	Pieza
260	21100258	Unicel	Pieza
261	21100259	Marcador (plumon)	Pieza
262	21100260	Puntilla o mina	Pieza
263	21100261	Protector de plastico para hojas	Pieza
264	21100262	Hoja de transferencia para circuitos impresos	Pieza
265	21100263	Caja para archivo	Pieza
266	21100264	Cera cuenta facil	Pieza
267	21100265	Marco para carpeta de archivo	Pieza
268	21100266	Kit de computador de vuelo	Pieza
269	21100267	Plotter aeronautico	Pieza
270	21100268	Papel mampara	Pieza
271	21100269	Playo	Pieza
272	21100270	Llavero	Pieza
273	21100271	Cinta correctora	Pieza
274	21100272	Bolsas de papel	Pieza
275	21100273	Cordon para gafete	Pieza
276	21100274	Despachador de notas adhesivas	Pieza
277	21100275	Cinta doblecara	Pieza
278	21100276	Formas pre impresas	Pieza
279	21100277	Almohadilla (mouse pad)	Pieza
280	21100278	Pintarron	Pieza
281	21100279	Porta planos	Pieza
282	21100280	Cintillas o cincho	Pieza
283	21100281	Rollo de corcho	Pieza
284	21100282	Bitacora de obra	Pieza
285	2120	Materiales y utiles de impresion y reproduccion	
286	21201	Materiales y utiles de impresion y reproduccion	
287	21200001	Acetato para fotocopiadora	Pieza
288	21200002	Acetato transparencias serigraficas	Pieza
289	21200003	Aplicador tinta (rodillos)	Pieza
290	21200004	Banda acero mimeografo	Pieza
291	21200005	Bandas autoadheribles para sellado	Pieza
292	21200006	Bobina papel	Pieza
293	21200007	Carrete o bobina pelicula	Pieza
294	21200008	Charola revelado	Pieza
295	21200009	Cliche	Pieza
296	21200010	Colores retoque	Pieza
297	21200011	Cuña imprenta	Pieza
298	21200012	Delantal revelado	Pieza
299	21200013	Esponja (lavar negativos)	Pieza
300	21200014	Estuche guardar pelicula	Pieza
301	21200015	Fijador	Pieza
302	21200016	Flash desechable	Pieza
303	21200017	Foco camara cinematografica	Pieza
304	21200018	Foco proyector cinematografico	Pieza
305	21200019	Papel fotografico	Pieza
306	21200020	Parche o sello pelicula	Pieza
307	21200021	Peliculas fotograficas	Pieza
308	21200022	Placa radiografica	Pieza
309	21200023	Prensador transparencias	Pieza
310	21200024	Removedor	Pieza
311	21200025	Revelador y fijadores	Pieza
312	21200026	Rollo para fotografia	Pieza
313	21200027	Rollo para pelicula	Pieza
314	21200028	Suministro de micropeliculas	Pieza
315	21200029	Tapa (lente fotografico)	Pieza
316	21200030	Toner	Pieza
317	21200031	Video-cassette (cartucho)	Pieza
318	21200032	Estuche camara fotografica	Pieza
319	21200033	Parasol camara	Pieza
320	21200034	Sombrilla difusora flash	Pieza
321	21200035	Acetato para impresora	Pieza
322	21200036	Percalina	Pieza
323	21200037	Placa	Pieza
324	21200038	Polvo impresor	Pieza
325	21200039	Cinta para impresion termica	Pieza
326	21200040	Cinta de retransferencia	Pieza
327	21200041	Cinta holografica	Pieza
328	2130	Material estadistico y geografico	
329	21301	Materiales y utiles de impresion y reproduccion	
330	21300001	Mapas	Pieza
331	21300002	Planos	Pieza
332	2140	Materiales, utiles y equipos menores de tecnologias de la informacion y comunicaciones	
333	21401	Materiales y utiles consumibles para el procesamiento en equipos y bienes informaticos	
334	21400001	Brocha antiestatica (suministros informaticos)	Pieza
335	21400002	Cintas magneticas (suministros informaticos)	Pieza
336	21400003	Cintas magneticas de cassette (suministros informaticos)	Pieza
337	21400004	Cintas para impresora (suministros informaticos)	Pieza
338	21400005	Compiladores (suministros informaticos)	Pieza
339	21400006	Disco compacto, CD y DVD (suministros informaticos)	Pieza
340	21400007	Discos magneticos flexibles (suministros informaticos)	Pieza
341	21400008	Enchufe de corriente de automovil para microcomputadora (suministros informaticos)	Pieza
342	21400009	Ensambladores (suministros informaticos)	Pieza
343	21400010	Filtro optico (suministros informaticos)	Pieza
344	56300091	Pala mecanica	Pieza
345	21400011	Manuales de informatica (suministros informaticos)	Pieza
346	21400012	Papel formas continuas (suministros informaticos)	Pieza
347	21400013	Porta-diskettes (suministros informaticos)	Pieza
348	21400014	Portamonitor (suministros informaticos)	Pieza
349	21400015	Sistemas de aplicacion administrativa (suministros informaticos)	Pieza
350	21400016	Sistemas de aplicacion cientificas (suministros informaticos)	Pieza
351	21400017	Sistemas operativos (suministros informaticos)	Pieza
352	21400018	Tarjetas para procesamiento de datos (suministros informaticos)	Pieza
353	21400019	Tinta para impresion (suministros informaticos)	Pieza
354	21400020	Tinta para marcas magneticas (suministros informaticos)	Pieza
355	21400021	Traductores (suministros informaticos)	Pieza
356	21400022	Adaptador de discos duros	Pieza
357	21400023	Toallas antiestaticas	Pieza
358	21400024	Cable usb	Pieza
359	21400025	Cable utp	Pieza
360	21400026	Discos duros	Pieza
361	21400027	Dispositivos USB	Pieza
362	21400028	Materiales para limpieza de equipos (solventes)	Pieza
363	21400029	Accesorios para proteccion de equipos (fundas, protectores de video)	Pieza
364	21400030	Sopladora compacta	Pieza
365	2150	Material impreso e informacion digital	
366	21501	Material de apoyo informativo	
367	21500003	Material audiovisual	Pieza
368	21500007	Disco compacto (cd rom)	Pieza
369	21500014	Periodico (papel prensa)	Pieza
370	21500040	Boletines	Pieza
371	21500041	Folletos	Pieza
372	21500042	Libros	Pieza
373	21500043	Periodicos	Pieza
374	21500044	Revistas	Pieza
375	21500045	Gacetas	Pieza
376	21500046	Recetario	Pieza
377	21502	Material para informacion en actividades de investigacion cientifica y tecnologica	
378	21500004	Boletines	Pieza
379	21500008	Folletos	Pieza
380	21500011	Libros	Pieza
381	21500015	Periodicos	Pieza
382	21500020	Revistas	Pieza
383	21500022	Gacetas	Pieza
384	21500024	Pictograma	Pieza
385	2160	Material de limpieza	
386	21601	Material de limpieza	
387	21600001	Aceite para muebles	Litro
388	21600002	Agentes quimicos para limpieza como acido muriatico y sosa	Litro
389	21600004	Atomizador	Pieza
390	21600005	Blanqueador	Litro
391	21600006	Botador	Pieza
392	21600007	Burro de planchar	Pieza
393	21600008	Camara basura	Pieza
394	21600009	Carro transportar basura	Pieza
395	21600010	Cepillos para limpieza	Pieza
396	21600011	Compactador de basura	Pieza
397	21600012	Cubeta	Pieza
398	21600013	Cuñete	Pieza
399	21600014	Desinfectante	Litro
400	21600015	Desodorante	Litro
401	21600016	Destapacaños (liquido)	Litro
402	21600017	Detergentes	Kilogramo
403	21600018	Eliminador de insectos	Pieza
404	21600019	Escalera marina	Pieza
405	21600020	Escobas	Pieza
406	21600021	Escobetas	Pieza
407	21600022	Escobillones para limpieza	Pieza
408	21600023	Esponja	Pieza
409	21600024	Espumador	Pieza
410	21600025	Estrobo	Pieza
411	21600026	Estropajo	Pieza
412	21600027	Felpa	Metro Cuadrado
413	21600028	Fibra	Pieza
414	21600029	Franela	Metro Cuadrado
415	21600030	Jabon en  pasta	Pieza
416	21600031	Jabon en polvo	Pieza
417	21600032	Jabon liquido	Pieza
418	21600033	Jabonera	Pieza
419	21600034	Jabones para cuerpo	Pieza
420	21600035	Jalador de agua	Pieza
421	21600036	Jardinera	Pieza
422	21600037	Limpiador de metales	Pieza
423	21600038	Limpiador para muebles	Pieza
424	21600039	Mechudo	Pieza
425	21600040	Microspray	Pieza
426	21600041	Papel facial	Pieza
427	21600042	Papel higienico	Pieza
428	21600043	Papel toalla	Pieza
429	21600044	Piedra pomez	Pieza
430	21600045	Plancha	Pieza
431	21600046	Plumero	Pieza
432	21600047	Polaina soldar	Pieza
433	21600048	Porta jergas	Pieza
434	21600049	Porta plancha	Pieza
435	21600050	Porta rollo (papel higienico)	Pieza
436	21600051	Recogedor	Pieza
437	21600052	Toallas sanitarias de papel	Pieza
438	21600053	Toallero (toalla papel)	Pieza
439	21600054	Trapeador	Pieza
440	21600055	Aserrin para limpiar piso	Kilogramo
441	21600056	Aerosol para limpieza de componentes electronicos	Pieza
442	21600057	Ahulada para maquina pulidora	Pieza
443	21600058	Alcohol isopropilico	Litro
444	21600059	Almohadilla abrasiva	Pieza
445	21600060	Articulos de higiene personal	Pieza
446	21600061	Detergente de limpieza medico o de laboratorio	Kilogramo
447	21600062	Espuma antibacteriana	Pieza
448	21600063	Espuma antimicrobiana	Pieza
449	21600065	Gel antibacterial	Kilogramo
450	21600066	Jerga	Metro Cuadrado
451	21600067	Limpiador	Pieza
452	21600068	Pastillas desinfectantes para baño	Pieza
453	21600069	Recipiente	Pieza
454	21600070	Sarricida	Litro
455	21600071	Champu (shampoo)	Litro
456	21600072	Suavizante	Litro
457	22300084	Vinagrera	Pieza
458	21600073	Accesorios de belleza personal	Pieza
459	21600074	Sanitizantes	Litro
460	21600075	Bolsas para basura	Pieza
461	21600076	Pañuelos desechables	Pieza
462	21600077	Despachador de jabon	Pieza
463	21600078	Solvente dielectrico	Pieza
464	21600079	Desengrasante	Pieza
465	2170	Materiales y utiles de enseñanza	
466	21701	Materiales y suministros para planteles educativos	
467	21700001	Gis	Pieza
468	21700002	Pedal instrumento musical percusion	Pieza
469	21700003	Alfabeto movil	Pieza
470	21700004	Apuntador laser	Pieza
471	21700005	Libro infantil	Pieza
472	21700006	Libro para colorear	Pieza
473	21700007	Figuras didacticas	Pieza
474	21700008	Geoplano didactico	Pieza
475	21700009	Guia alfabetica	Pieza
476	21700010	Guiñoles	Pieza
477	21700011	Juguetes	Pieza
478	21700012	Plastilina	Pieza
479	21700013	Material didactico para manualidades escolares	Pieza
480	21700014	Abaco	Pieza
481	21700015	Caja de letras (material didactico)	Pieza
482	21700016	Cuerpo geometrico	Pieza
483	21700017	Juego geometrico escolar	Pieza
484	21700018	Juego geometrico pizarron	Pieza
485	21700019	Libros de texto escolares	Pieza
486	21700020	Modulo de plastico	Pieza
487	21700021	Porta gis	Pieza
488	21700022	Pupitre para estudio de logica digital	Pieza
489	21700023	Tablero didactico	
490	2180	Materiales para el registro e identificacion de bienes y personas	
491	2200	Alimentos y utensilios	
492	2210	Productos alimenticios para personas	
493	22101	Productos alimenticios para el Ejercito, Fuerza Aerea y Armada Mexicanos, y para los efectivos que participen en programas de seguridad publica	
494	22100393	Productos alimenticios para el Ejercito, Fuerza Aerea y Armada Mexicanos, y para los efectivos que participen en programas de seguridad publica	Pieza
495	22102	Productos alimenticios para personas derivado de la prestacion de servicios publicos en unidades de salud, educativas, de readaptacion social y otras	
496	22100394	Productos alimenticios para personas derivado de la prestacion de servicios publicos en unidades de salud, educativas, de readaptacion social y otras	Pieza
497	22103	Productos alimenticios para el personal que realiza labores en campo o de supervision	
498	22100395	Productos alimenticios para el personal que realiza labores en campo o de supervision	Pieza
499	22104	Productos alimenticios para el personal en las instalaciones de las dependencias y entidades	
500	22100001	Abulon (para alimentacion)	Kilogramo
501	22100002	Abulon preparado y enlatado	Kilogramo
502	22100003	Aceite vegetal comestible de ajonjoli	Litro
503	22100004	Aceite vegetal comestible de algodon	Litro
504	22100005	Aceite vegetal comestible de cartamo	Litro
505	22100006	Aceite vegetal comestible de oliva	Litro
506	22100007	Aceite vegetal comestible de soya	Litro
507	22100008	Aceituna (frutas)	Kilogramo
508	22100009	Aceitunas preparadas	Kilogramo
509	22100010	Acelga (hortaliza)	Kilogramo
510	22100011	Agua purificada	Litro
511	22100012	Aguacate (frutas)	Kilogramo
512	22100013	Aguardientes	Litro
513	22100014	Aguas gaseosas	Litro
514	22100015	Ajo (hortaliza)	Kilogramo
515	22100016	Ajonjoli (oleaginosa) (hortaliza)	Kilogramo
516	22100017	Alcachofa (hortaliza)	Kilogramo
517	22100018	Almeja (para alimentacion)	Kilogramo
518	22100019	Almeja preparada y/o enlatada	Kilogramo
519	22100020	Almidon de maiz	Kilogramo
520	22100021	Anona (frutas)	Kilogramo
521	22100022	Apio (hortaliza)	Kilogramo
522	22100023	Arroz (hortaliza)	Kilogramo
523	22100024	Alberjon (hortaliza)	Kilogramo
524	22100025	Ates de frutas	Kilogramo
525	22100026	Atun (para alimentacion)	Kilogramo
526	22100027	Atun preparado y/o enlatado	Pieza
527	22100028	Avena en grano (hortaliza)	Kilogramo
528	22100029	Azucar	Kilogramo
529	22100030	Bacalao (para alimentacion)	Kilogramo
530	22100031	Bacalao preparado y/o enlatado	Kilogramo
531	22100032	Berenjena (hortaliza)	Kilogramo
532	22100033	Berro (hortaliza)	Kilogramo
533	22100034	Betabel (hortaliza)	Kilogramo
534	22100035	Brocoli (hortaliza)	Kilogramo
535	22100036	Cacahuate (oleaginosa) (hortaliza)	Kilogramo
536	22100037	Cacao en grano (frutas)	Kilogramo
537	22100038	Cafe en grano (frutas)	Kilogramo
538	22100039	Cafe molido	Kilogramo
539	22100040	Cafe soluble	Kilogramo
540	22100041	Cafe tostado	Kilogramo
541	22100042	Caimilo (frutas)	Kilogramo
542	22100043	Cajetas de leche (leche quemada)	Kilogramo
543	22100044	Calabacita tierna (hortaliza)	Kilogramo
544	22100045	Calabaza (hortaliza)	Kilogramo
545	22100046	Calabaza (semilla)	Kilogramo
546	22100047	Calamar (para alimentacion)	Kilogramo
547	22100048	Calamar preparado y/o enlatado	Pieza
548	22100049	Camaron (para alimentacion)	Kilogramo
549	22100050	Camaron preparado y/o enlatado	Pieza
550	22100051	Camote (hortaliza)	Kilogramo
551	22100052	Canela	Kilogramo
552	22100053	Cangrejo (para alimentacion)	Kilogramo
553	22100054	Cangrejo preparado y/o enlatado	Pieza
554	22100055	Caña de azucar (hortaliza)	Kilogramo
555	22100056	Capulin (frutas)	Kilogramo
556	22100057	Caracol de mar (para alimentacion)	Kilogramo
557	22100058	Caracol de mar preparado y/o enlatado	Pieza
558	22100059	Caramelos, bombones y confites	Kilogramo
559	22100060	Carne de asnal preparada y/o enlatada	Pieza
560	22100061	Carne de bovino preparada y/o enlatada	Pieza
561	22100062	Carne de caballar preparada y/o enlatada	Pieza
562	22100063	Carne de caprino preparada y/o enlatada	Pieza
563	22100064	Carne de gallina preparada y/o enlatada	Pieza
564	22100065	Carne de gallo preparada y/o enlatada	Pieza
565	22100066	Carne de ganso preparada y/o enlatada	Pieza
566	22100067	Carne de guajolote preparada y/o enlatada	Pieza
567	22100068	Carne de ovino preparada y/o enlatada	Pieza
568	22100069	Carne de pato preparada y/o enlatada	Pieza
569	22100070	Carne de pollo preparada y/o enlatada	Pieza
570	22100071	Carne de porcino preparada y/o enlatada	Pieza
571	22100072	Carpa preparada y/o enlatada	Pieza
572	22100073	Cartamo (hortaliza)	Kilogramo
573	22100074	Cazon (tiburon) preparado y/o enlatado	Pieza
574	22100075	Cebolla (hortaliza)	Kilogramo
575	22100076	Centeno (hortaliza)	Kilogramo
576	22100077	Cereales	Kilogramo
577	22100078	Cereza (frutas)	Kilogramo
578	22100079	Cerveza	Kilogramo
579	22100080	Chabacano (albaricoque) (frutas)	Kilogramo
580	22100081	Charal (para alimentacion)	Kilogramo
581	22100082	Charal preparado y/o enlatado	Pieza
582	22100083	Chayote (hortaliza)	Kilogramo
583	22100084	Chia (hortaliza)	Kilogramo
584	22100085	Chicharo (hortaliza)	Kilogramo
585	22100086	Chicharron de camaron preparado y/o enlatado	Pieza
586	22100087	Chile (seco) (hortaliza)	Kilogramo
587	22100088	Chile verde (hortaliza)	Kilogramo
588	22100089	Chiles en conserva	Kilogramo
589	22100090	Chirimoya (frutas)	Kilogramo
590	22100091	Chocolate de mesa	Kilogramo
591	22100092	Cilantro (hortaliza)	Kilogramo
592	22100093	Ciruela (frutas)	Kilogramo
593	22100094	Ciruela de almendra (frutas)	Kilogramo
594	22100095	Coco (frutas)	Kilogramo
595	22100096	Codorniz (carne fresca)	Kilogramo
596	22100097	Codorniz (para fomento y abasto)	Pieza
597	22100098	Col (hortaliza)	Kilogramo
598	22100099	Coliflor (hortaliza)	Kilogramo
599	22100100	Colinabo (hortaliza)	Kilogramo
600	22100101	Comino	Kilogramo
601	22100102	Conejo (carne fresca)	Kilogramo
602	22100103	Conejo (para fomento y abasto)	Pieza
603	22100104	Consomes	Litro
604	22100105	Copra (frutas)	Kilogramo
605	22100106	Coquito aceite (frutas)	Kilogramo
606	22100107	Corozo (hortaliza)	Kilogramo
607	22100108	Coyol (frutas)	Kilogramo
608	22100109	Crema condensada	Kilogramo
609	22100110	Crema en polvo	Kilogramo
610	22100111	Crema fresca	Kilogramo
611	22100112	Datil (frutas)	Kilogramo
612	22100113	Despensas (productos alimenticios)	Pieza
613	22100114	Durazno (frutas)	Kilogramo
614	22100115	Ejote (hortaliza)	Kilogramo
615	22100116	Embutidos de pollo y puerco	Kilogramo
616	22100117	Esencias y sabores	Kilogramo
617	22100118	Esparragos (hortaliza)	Kilogramo
618	22100119	Especias	Kilogramo
619	22100120	Espinaca (hortaliza)	Kilogramo
620	22100121	Fecula de maiz	Kilogramo
621	22100122	Fecula de trigo	Kilogramo
622	22100123	Fresa (frutas)	Kilogramo
623	22100124	Frijol (hortaliza)	Kilogramo
624	22100125	Frituras (botanas)	Kilogramo
625	22100126	Frutas congeladas	Kilogramo
626	22100127	Frutas en conserva	Kilogramo
627	22100128	Galletas	Kilogramo
628	22100129	Gallina (para fomento y abasto)	Pieza
629	22100130	Gallo (para fomento y abasto)	Pieza
630	22100131	Ganado bovino (carne en canal)	Kilogramo
631	22100132	Ganado bovino (en pie)	Pieza
632	22100133	Ganado caprino (carne en canal)	Kilogramo
633	22100134	Ganado caprino (en pie)	Pieza
634	22100135	Ganado ovino (carne en canal)	Kilogramo
635	22100136	Ganado ovino (en pie)	Pieza
636	22100137	Ganado porcino (carne en canal)	Kilogramo
637	22100138	Ganado porcino (en pie)	Pieza
638	22100139	Ganso (carne fresca)	Kilogramo
639	22100140	Ganso (para fomento y abasto)	Pieza
640	22100141	Garbanzo (hortaliza)	Kilogramo
641	22100142	Gelatina	Kilogramo
642	22100143	Granada (frutas)	Kilogramo
643	22100144	Guachinango preparado y/o enlatado	Pieza
644	22100145	Guajolote (para fomento y abasto)	Pieza
645	22100146	Guajolote o pavo (carne fresca)	Kilogramo
646	22100147	Guamuchil (frutas)	Kilogramo
647	22100148	Guanabana (frutas)	Kilogramo
648	22100149	Guayaba (frutas)	Kilogramo
649	22100150	Haba (hortaliza)	Kilogramo
650	22100151	Harina de arroz	Kilogramo
651	22100152	Harina de centeno	Kilogramo
652	22100153	Harina de frutas	Kilogramo
653	22100154	Harina de maiz	Kilogramo
654	22100155	Harina de soya	Kilogramo
655	22100156	Harina de trigo	Kilogramo
656	22100157	Harina de tuberculos	Kilogramo
657	22100158	Hielo y helados	Kilogramo
658	22100159	Higo (frutas)	Kilogramo
659	22100160	Huevo (productos comestibles)	Kilogramo
660	22100161	Jaiba (para alimentacion)	Kilogramo
661	22100162	Jaiba preparada y/o enlatada	Pieza
662	22100163	Jalea real (productos comestibles)	Kilogramo
663	22100164	Jamaica (hortaliza)	Kilogramo
664	22100165	Jarabe y mieles	Kilogramo
665	22100166	Jicama (frutas)	Kilogramo
666	22100167	Jicama (hortaliza)	Kilogramo
667	22100168	Jugos de frutas envasados o enlatados	Pieza
668	22100169	Langosta de mar (para alimentacion)	Kilogramo
669	22100170	Langosta de mar preparada y/o enlatada	Pieza
670	22100171	Langostino (para alimentacion)	Kilogramo
671	22100172	Langostino preparado y/o enlatado	Pieza
672	22100173	Leche (productos comestibles)	Litro
673	22100174	Leche condensada	Litro
674	22100175	Leche en pastillas	Pieza
675	22100176	Leche en polvo	Kilogramo
676	22100177	Leche evaporada	Litro
677	22100178	Leche maternizada	Litro
678	22100179	Leche pasteurizada	Litro
679	22100180	Leche reconstituida	Litro
680	22100181	Lechuga (hortaliza)	Kilogramo
681	22100182	Legumbres	Kilogramo
682	22100183	Legumbres en conserva	Kilogramo
683	22100184	Lenteja (hortaliza)	Kilogramo
684	22100185	Levadura y polvos de hornear	Kilogramo
685	22100186	Licores	Litro
686	22100187	Lima (frutas)	Kilogramo
687	22100188	Limon (frutas)	Kilogramo
688	22100189	Litchi (frutas)	Kilogramo
689	22100190	Macal (hortaliza)	Kilogramo
690	22100191	Macarela (para alimentacion)	Kilogramo
691	22100192	Macarela enlatada y/o preparada	Pieza
692	22100193	Maguey (hortaliza)	Kilogramo
693	22100194	Maiz (hortaliza)	Kilogramo
694	22100195	Mamey (frutas)	Kilogramo
695	22100196	Mandarina (frutas)	Kilogramo
696	22100197	Mango (frutas)	Kilogramo
697	22100198	Manteca vegetal	Kilogramo
698	22100199	Mantequilla	Kilogramo
699	22100200	Manzana y peron (frutas)	Kilogramo
700	22100201	Maranah (frutas)	Kilogramo
701	22100202	Margarina	Kilogramo
702	22100203	Melon (frutas)	Kilogramo
703	22100204	Membrillo (frutas)	Kilogramo
704	22100205	Mezcal y tequila	Litro
705	22100206	Miel de abeja (productos comestibles)	Kilogramo
706	22100207	Mojarra preparada y/o enlatada	Pieza
707	22100208	Nabo (hortaliza)	Kilogramo
708	22100209	Nabo (semilla)	Kilogramo
709	22100210	Nanche (frutas)	Kilogramo
710	22100211	Naranja (frutas)	Kilogramo
711	22100212	Nuez de castilla (frutas)	Kilogramo
712	22100213	Nuez pecana	Kilogramo
713	22100214	Ostion (para alimentacion)	Kilogramo
714	22100215	Ostion preparado y/o enlatado	Pieza
715	22100216	Pan (blanco y de dulce)	Kilogramo
716	22100217	Papa (hortaliza)	Kilogramo
717	22100218	Papaya (frutas)	Kilogramo
718	22100219	Pastas para sopas	Kilogramo
719	22100220	Pasteles	Kilogramo
720	22100221	Pato (carne fresca)	Kilogramo
721	22100222	Pato (para fomento y abasto)	Kilogramo
722	22100223	Pera (frutas)	Kilogramo
723	22100224	Pescados (para alimentacion)	Kilogramo
724	22100225	Pescados carpa (para alimentacion)	Kilogramo
725	22100226	Pescados cazon (para alimentacion)	Kilogramo
726	22100227	Pescados guachinango (para alimentacion)	Kilogramo
727	22100228	Pescados mojarra (para alimentacion)	Kilogramo
728	22100229	Pescados sabalo (para alimentacion)	Kilogramo
729	22100230	Pescados sierra (para alimentacion)	Kilogramo
730	22100231	Piloncillo	Kilogramo
731	22100232	Pimienta	Kilogramo
732	22100233	Piña (frutas)	Kilogramo
733	22100234	Piñon (frutas)	Kilogramo
734	22100235	Platano (frutas)	Kilogramo
735	22100236	Pollo (carne fresca)	Kilogramo
736	22100237	Pollo (para fomento y abasto)	Pieza
737	22100238	Pulpo (para alimentacion)	Kilogramo
738	22100239	Pulpo preparado y/o enlatado	Pieza
739	22100240	Queso chihuahua	Kilogramo
740	22100241	Queso oaxaca	Kilogramo
741	22100242	Queso panela	Kilogramo
742	22100243	Quesos (para alimentacion)	Kilogramo
743	22100244	Rabano (hortaliza)	Kilogramo
744	22100245	Refresco	Kilogramo
745	22100246	Remolacha (hortaliza)	Kilogramo
746	22100247	Requeson	Kilogramo
747	22100248	Robalo preparado y/o enlatado	Pieza
748	22100249	Sabalo preparado y/o enlatado	Pieza
749	22100250	Sal para uso alimenticio	Kilogramo
750	22100251	Salmon (para alimentacion)	Kilogramo
751	22100252	Salmon preparado y/o enlatado	Pieza
752	22100253	Sandia (frutas)	Kilogramo
753	22100254	Sardina (para alimentacion)	Kilogramo
754	22100255	Sardina enlatada y/o preparada	Pieza
755	22100256	Soya (hortaliza)	Kilogramo
756	22100257	Suero de leche	Kilogramo
757	22100258	Sustituto de azucar	Kilogramo
758	22100259	Sustituto de crema	Kilogramo
759	22100260	Tamarindo (frutas)	Kilogramo
760	22100261	Te	Kilogramo
761	22100262	Tejocote (frutas)	Kilogramo
762	22100263	Tomate rojo (hortaliza)	Kilogramo
763	22100264	Tomate verde (hortaliza)	Kilogramo
764	22100265	Toronja (frutas)	Kilogramo
765	22100266	Tortillas de harina	Kilogramo
766	22100267	Tortillas de maiz	Kilogramo
767	22100268	Trigo (hortaliza)	Kilogramo
768	22100269	Tuna (frutas)	Kilogramo
769	22100270	Uva (frutas)	Kilogramo
770	22100271	Vainilla (hortaliza)	Kilogramo
771	22100272	Verduras	Kilogramo
772	22100273	Verduras en conserva	Kilogramo
773	22100274	Vinos y licores	Kilogramo
774	22100275	Visceras (carne fresca)	Kilogramo
775	22100276	Yogurts	Litro
776	22100277	Zanahoria (hortaliza)	Kilogramo
777	22100278	Zapote (frutas)	Kilogramo
778	22100279	Zapote chico (chicozapote) (frutas)	Kilogramo
779	22100280	Ablandador de carne	Kilogramo
780	22100281	Aceite de girasol	Litro
781	22100282	Aceite de maiz	Litro
782	22100283	Aceite de oliva	Litro
783	22100284	Aceituna	Kilogramo
784	22100285	Acelga	Kilogramo
785	22100286	Achiote	Kilogramo
786	22100287	Acitron	Kilogramo
787	22100288	Aderezos	Kilogramo
788	22100289	Agua embotellada para beber	Pieza
789	22100290	Aguacate	Kilogramo
790	22100291	Ajo	Kilogramo
791	22100292	Albahaca	Kilogramo
792	22100293	Alcachofa	Kilogramo
793	22100294	Alcaparra	Kilogramo
794	22100295	Alfajor coco	Kilogramo
795	22100296	Almeja blanca	Kilogramo
796	22100297	Alubias	Kilogramo
797	22100298	Anchoas	Kilogramo
798	22100299	Apio	Kilogramo
799	22100300	Ate	Kilogramo
800	22100301	Barras de cereal	Pieza
801	22100302	Base para pizza	Pieza
802	22100303	Berenjena	Kilogramo
803	22100304	Berro	Kilogramo
804	22100305	Betabel	Kilogramo
805	22100306	Bocadillos	Kilogramo
806	22100307	Callos	Kilogramo
807	22100308	Camaron	Kilogramo
808	22100309	Canape	Kilogramo
809	22100310	Canelon	Kilogramo
810	22100311	Catsup	Kilogramo
811	22100312	Cebolla	Kilogramo
812	22100313	Cebollin	Kilogramo
813	22100314	Cemitas	Kilogramo
814	22100315	Champiñones (hongos)	Kilogramo
815	22100316	Chaya/ verdolaga	Kilogramo
816	22100317	Chayote	Kilogramo
817	22100318	Chicharo	Kilogramo
818	22100319	Chicharron	Kilogramo
819	22100320	Chicozapote	Kilogramo
820	22100321	Chilaca	Kilogramo
821	22100322	Chilacate	Kilogramo
822	22100323	Chilacayote	Kilogramo
823	22100324	Chilmole	Kilogramo
824	22100325	Chilorio	Kilogramo
825	22100326	Chipotles	Kilogramo
826	22100327	Chocolate	Kilogramo
827	22100328	Chongos zamoranos	Kilogramo
828	22100329	Cilantro	Kilogramo
829	22100330	Cocada	Kilogramo
830	22100331	Coco	Kilogramo
831	22100332	Coctel de frutas	Kilogramo
832	22100333	Col	Kilogramo
833	22100334	Coliflor	Kilogramo
834	22100335	Productos preparados	Kilogramo
835	22100336	Crema batida	Kilogramo
836	22100337	Crema enlatada	Pieza
837	22100338	Cuitlacoche (Huitlacoche)	Kilogramo
838	22100339	Durazno	Kilogramo
839	22100340	Ejote	Kilogramo
840	22100341	Empanizador	Kilogramo
841	22100342	Ensalada  verduras	Kilogramo
842	22100343	Epazote	Kilogramo
843	22100344	Flan	Kilogramo
844	22100345	Frambuesa (fruta)	Kilogramo
845	22100346	Frutos secos	Kilogramo
846	22100347	Germen	Kilogramo
847	22100348	Germinado	Kilogramo
848	22100349	Golosinas	Kilogramo
849	22100350	Granola	Kilogramo
850	22100351	Helado	Kilogramo
851	22100353	Huazontles	Kilogramo
852	22100354	Jamon	Kilogramo
853	22100355	Kiwi (fruta)	Kilogramo
854	22100357	Maracuya (fruta)	Kilogramo
855	22100358	Marañon (fruta)	Kilogramo
856	22100359	Machaca	Kilogramo
857	22100360	Mayonesa	Kilogramo
858	22100361	Mermelada	Kilogramo
859	22100362	Mora (fruta)	Kilogramo
860	22100363	Morron	Kilogramo
861	22100364	Mostaza	Kilogramo
862	22100365	Pasas	Kilogramo
863	22100366	Pepino	Kilogramo
864	22100367	Perejil	Kilogramo
865	22100368	Pimenton	Kilogramo
866	22100370	Pimiento	Kilogramo
867	22100371	Pinole	Kilogramo
868	22100372	Pipicha	Kilogramo
869	22100373	Pitaya	Kilogramo
870	22100374	Polvo para hornear	Kilogramo
871	22100375	Poro	Kilogramo
872	22100376	Pulpa	Kilogramo
873	22100377	Pure	Kilogramo
874	22100378	Quelite	Kilogramo
875	22100379	Romeritos	Kilogramo
876	22100380	Salchicha	Kilogramo
877	22100381	Salsa	Kilogramo
878	22100382	Sopa de Pasta	Kilogramo
879	22100383	Surimi	Kilogramo
880	22100384	Tamal	Pieza
881	22100385	Tlacoyo	Pieza
882	22100386	Tocino	Kilogramo
883	22100387	Tostadas	Kilogramo
884	22100388	Verdolaga	Kilogramo
885	22100389	Vinagre	Litro
886	22100390	Xoconostle	Kilogramo
887	22100391	Zapote	Kilogramo
888	22100392	Zarzamora	Kilogramo
889	22100398	Semilla	Kilogramo
890	22100399	Cafe instantaneo preparado	Kilogramo
891	22105	Productos alimenticios para la poblacion en caso de desastres naturales	
892	22100396	Productos alimenticios para la poblacion en caso de desastres naturales	Pieza
893	56300092	Pavimentadora	Pieza
894	22106	Productos alimenticios para el personal derivado de actividades extraordinarias	
895	22100397	Productos alimenticios para el personal derivado de actividades extraordinarias	Pieza
896	2220	Productos alimenticios para animales	
897	22201	Productos alimenticios para animales	
898	22200001	Alfalfa (forraje)	Kilogramo
899	22200002	Alfalfa (hortaliza)	Kilogramo
900	22200003	Alimentos preparados para aves de corral	Kilogramo
901	22200004	Alimentos preparados para ganado	Kilogramo
902	22200005	Alpiste (hortaliza)	Kilogramo
903	22200006	Avena (forraje)	Kilogramo
904	22200007	Carne de mular preparada y/o enlatada	Pieza
905	22200008	Cebada (forraje)	Kilogramo
906	22200009	Cebada en grano (hortaliza)	Kilogramo
907	22200010	Ganado asnal (carne en canal)	Kilogramo
908	22200011	Ganado asnal (en pie)	Pieza
909	22200012	Ganado equino (carne en canal)	Kilogramo
910	22200013	Ganado equino (en pie)	Pieza
911	22200014	Ganado mular (carne en canal)	Kilogramo
912	22200015	Ganado mular (en pie)	Pieza
913	22200016	Garbanzo (forraje)	Kilogramo
914	22200017	Harina de pescado	Kilogramo
915	22200018	Maiz (forraje)	Kilogramo
916	22200019	Nopal (forraje)	Kilogramo
917	22200020	Paja (forraje)	Kilogramo
918	22200021	Pasto (forraje)	Kilogramo
919	22200022	Remolacha (forraje)	Kilogramo
920	22200023	Sorgo (forraje)	Kilogramo
921	22200024	Sorgo (hortaliza)	Kilogramo
922	22200025	Zacate (forraje)	Kilogramo
923	22200026	Alimentos preparados para perros	Kilogramo
924	22200027	Alimento para roedor	Kilogramo
925	22200028	Alimento para peces	Kilogramo
926	2230	Utensilios para el servicio de alimentacion	
927	22301	Utensilios para el servicio de alimentacion	
928	22300001	Abrelatas (manual o electrico)	Pieza
929	22300002	Aguamanil	Pieza
930	22300003	Anafre	Pieza
931	22300004	Aplanador manual carne (articulos para comercios)	Pieza
932	22300005	Artesa	Pieza
933	22300006	Azucarera	Pieza
934	22300007	Bateria de cocina	Pieza
935	22300008	Bombonera	Pieza
936	22300009	Botanero	Pieza
937	22300010	Botellon	Pieza
938	22300011	Brasero	Pieza
939	22300012	Budinera	Pieza
940	22300013	Burbuja de acrilico (articulos para comercios)	Pieza
941	22300014	Cafetera (utensilio)	Pieza
942	22300015	Caja guardar cubiertos	Pieza
943	22300016	Cajete, escudilla o cuenco	Pieza
944	22300017	Canasta (uso domestico)	Pieza
945	22300018	Canastilla lavado loza	Pieza
946	22300019	Cazo	Pieza
947	22300020	Charola	Pieza
948	22300021	Colador	Pieza
949	22300022	Comal	Pieza
950	22300023	Copa	Pieza
951	22300024	Cubiertos desechables	Pieza
952	22300025	Cuchara mesa	Pieza
953	22300026	Cuchara-helado	Pieza
954	22300027	Cucharon de lamina (articulos para comercios)	Pieza
955	22300028	Cuchillo cocina	Pieza
956	22300029	Cuchillo electrico (cocina)	Pieza
957	22300030	Descorchador o tirabuzon	Pieza
958	22300031	Destapador envases	Pieza
959	22300032	Ensaladera	Pieza
960	22300033	Frasco	Pieza
961	22300034	Frutero (fuente) mesa	Pieza
962	22300035	Garabato ollas	Pieza
963	22300036	Hielera	Pieza
964	22300037	Jarra	Pieza
965	22300038	Jarro	Pieza
966	22300039	Jarron	Pieza
967	22300040	Juego cubiertos	Pieza
968	22300041	Juego utensilios manuales	Pieza
969	22300042	Lechera	Pieza
970	22300043	Licorera	Pieza
971	22300044	Metate	Pieza
972	22300045	Molcajete	Pieza
973	22300046	Molde para gelatina	Pieza
974	22300047	Molde para helado	Pieza
975	22300048	Molde para pan	Pieza
976	22300049	Molde para servicio de alimentacion	Pieza
977	22300050	Olla	Pieza
978	22300051	Olla express	Pieza
979	22300052	Palillero	Pieza
980	22300053	Pelador	Pieza
981	22300054	Picahielo	Pieza
982	22300055	Plato	Pieza
983	22300056	Plato desechable	Pieza
984	22300057	Platon	Pieza
985	22300058	Porta garrafon	Pieza
986	22300059	Porta servilletas	Pieza
987	22300060	Porta-vasos	Pieza
988	22300061	Rayador manual queso	Pieza
989	22300062	Refractario	Pieza
990	22300063	Sahumerio	Pieza
991	22300064	Salero	Pieza
992	22300065	Sarten	Pieza
993	22300066	Sarten electrico	Pieza
994	22300067	Sopera	Pieza
995	22300068	Tajo madera carne (articulos para comercios)	Pieza
996	22300069	Tarro	Pieza
997	22300070	Taza	Pieza
998	22300071	Tazon	Pieza
999	22300072	Tenedor mesa	Pieza
1000	22300073	Tetera	Pieza
1001	22300074	Thermo	Pieza
1002	22300075	Tibor	Pieza
1003	22300076	Tortilladora manual	Pieza
1004	22300077	Utensilios de metal para cocina (servir)	Pieza
1005	22300078	Utensilios de plastico para cocina (servir)	Pieza
1006	22300079	Utensilios para servir alimentos desechables (platos, vasos, cubiertos)	Pieza
1007	22300080	Vajilla	Pieza
1008	22300081	Vaso	Pieza
1009	22300082	Vaso con tapa	Pieza
1010	22300083	Vasos desechables	Pieza
1011	22300085	Wafflera	Pieza
1012	22300086	Escurridera	Pieza
1013	22300087	Ventilador portatil	Pieza
1014	22300088	Aplastador	Pieza
1015	22300089	Arrocera	Pieza
1016	22300090	Batidor manual	Pieza
1017	22300091	Cacerola	Pieza
1018	22300092	Cazuela	Pieza
1019	22300093	Contenedores	Pieza
1020	22300094	Cucharon	Pieza
1021	22300095	Duya	Pieza
1022	22300096	Espumadera	Pieza
1023	22300097	Flanera	Pieza
1024	22300098	Garrafones para agua	Pieza
1025	22300099	Popote	Pieza
1026	22300100	Porta cubiertos	Pieza
1027	22300101	Procesador de alimentos	Pieza
1028	22300102	Salsera	Pieza
1029	22300103	Tabla para picar alimentos	Pieza
1030	22300104	Tortillero	Pieza
1031	22300105	Trinche	Pieza
1032	22300106	Vitrolero	Pieza
1033	22300107	Volteador	Pieza
1034	22300108	Mandil	Pieza
1035	22300109	Licuadora	Pieza
1036	22300110	Filtros desechables	Pieza
1037	2300	Materias primas y materiales de produccion y comercializacion	
1038	2310	Productos alimenticios, agropecuarios y forestales adquiridos como materia prima	
1039	23101	Productos alimenticios, agropecuarios y forestales adquiridos como materia prima	
1040	23100001	Acelga (materias primas)	Kilogramo
1041	23100002	Ajo (materias primas)	Kilogramo
1042	23100003	Ajonjoli (oleaginosa) (materias primas)	Kilogramo
1043	23100004	Alcachofa (materias primas)	Kilogramo
1044	23100005	Algodon (semilla)	Kilogramo
1045	23100006	Almendra (materia prima vegetal)	Kilogramo
1046	23100007	Apio (materias primas)	Kilogramo
1047	23100008	Arroz (materias primas)	Kilogramo
1048	23100009	Alberjon (materias primas)	Kilogramo
1049	23100010	Avena en grano (materias primas)	Kilogramo
1050	23100011	Berenjena (materias primas)	Kilogramo
1051	23100012	Berro (materias primas)	Kilogramo
1052	23100013	Betabel (materias primas)	Kilogramo
1053	23100014	Brocoli (materias primas)	Kilogramo
1054	23100015	Cacahuate (materias primas)	Kilogramo
1055	23100016	Calabacita tierna (materias primas)	Kilogramo
1056	23100017	Calabaza (materias primas)	Kilogramo
1057	23100018	Calabaza (semilla) (materias primas)	Kilogramo
1058	23100019	Camote (materias primas)	Kilogramo
1059	23100020	Caña de azucar (materias primas)	Kilogramo
1060	23100021	Cartamo (materias primas)	Kilogramo
1061	23100022	Cascalote (materia prima vegetal)	Kilogramo
1062	23100023	Cebolla (materias primas)	Kilogramo
1063	23100024	Centeno (materias primas)	Kilogramo
1064	23100025	Chayote (materias primas)	Kilogramo
1065	23100026	Chia (materias primas)	Kilogramo
1066	23100027	Chicharo (materias primas)	Kilogramo
1067	23100028	Chicle (materia prima vegetal)	Kilogramo
1068	23100029	Chile (seco y verde) (materias primas)	Kilogramo
1069	23100030	Cilantro (materias primas)	Kilogramo
1070	23100031	Cogollos (materia prima vegetal)	Kilogramo
1071	23100032	Col (materias primas)	Kilogramo
1072	23100033	Coliflor (materias primas)	Kilogramo
1073	23100034	Colinabo (materias primas)	Kilogramo
1074	23100035	Corozo (materias primas)	Kilogramo
1075	23100036	Cortezas (excluye corcho y canela) (materia prima vegetal)	Kilogramo
1076	23100037	Ejote (materias primas)	Kilogramo
1077	23100038	Esparragos (materias primas)	Kilogramo
1078	23100039	Espinaca (materias primas)	Kilogramo
1079	23100040	Flor (materia prima vegetal)	Kilogramo
1080	23100041	Frijol (materias primas)	Kilogramo
1081	23100042	Garbanzo (materias primas)	Kilogramo
1082	23100043	Girasol (hortaliza)	Kilogramo
1083	23100044	Gomas (materia prima vegetal)	Kilogramo
1084	23100045	Gomorresina (materia prima vegetal)	Kilogramo
1085	23100046	Haba (materias primas)	Kilogramo
1086	23100047	Hierbas (materia prima vegetal)	Kilogramo
1087	23100048	Higuerilla (hortaliza)	Kilogramo
1088	23100049	Hojas (materia prima vegetal)	Kilogramo
1089	23100050	Jamaica (materias primas)	Kilogramo
1090	23100051	Jicama (materias primas)	Kilogramo
1091	23100052	Lechuga (materias primas)	Kilogramo
1092	23100053	Lenteja (materias primas)	Kilogramo
1093	23100054	Linaza (semilla)	Kilogramo
1094	23100055	Macal (materias primas)	Kilogramo
1095	23100056	Maguey (materias primas)	Kilogramo
1096	23100057	Maiz (materias primas)	Kilogramo
1097	23100058	Nabo (materias primas)	Kilogramo
1098	23100059	Nabo (semilla) (materias primas)	Kilogramo
1099	23100060	Nervaduras de hoja de palma (materia prima vegetal)	Kilogramo
1100	23100061	Papa (materias primas)	Kilogramo
1101	23100062	Pastas (materia prima vegetal)	Kilogramo
1102	23100063	Rabano (materias primas)	Kilogramo
1103	23100064	Raices (materia prima vegetal)	Kilogramo
1104	23100065	Remolacha (materias primas)	Kilogramo
1105	23100066	Rizomas (barbasco) (materia prima vegetal)	Kilogramo
1106	23100067	Soya (materias primas)	Kilogramo
1107	23100068	Tabaco en rama (hortaliza)	Kilogramo
1108	23100069	Tallo (materia prima vegetal)	Kilogramo
1109	23100070	Tomate rojo (materias primas)	Kilogramo
1110	23100071	Tomate verde (materias primas)	Kilogramo
1111	23100072	Trigo (materias primas)	Kilogramo
1112	23100073	Vainilla (materias primas)	Litro
1113	23100074	Zanahoria (materias primas)	Kilogramo
1114	23100075	Algodon en pluma	Kilogramo
1115	23100076	Henequen (pita e ixtle)	Kilogramo
1116	23100077	Kenaf	Metro
1117	23100078	Lino	Metro
1118	23100079	Palmas	Pieza
1119	23100080	Rafia	Metro
1120	23100081	Raiz zacaton	Pieza
1121	23100082	Tule	Kilogramo
1122	23100083	Alcornoque (corcho natural)	Kilogramo
1123	23100084	Aglomerado (corcho)	Kilogramo
1124	23100085	Corcho rudo o aspero	Kilogramo
1125	23100086	Empaques de corcho	Kilogramo
1126	23100087	Masas	Kilogramo
1127	23100088	Amaranto (materias primas)	Kilogramo
1128	23100089	Anis estrella  (materias primas)	Kilogramo
1129	23100090	Azafran  (materias primas)	Kilogramo
1130	23100091	Clavo de olor  (materias primas)	Kilogramo
1131	23100092	Extracto de frutas y/o verduras  (materias primas)	Litro
1132	23100093	Grenetina (materias primas)	Kilogramo
1133	23100094	Hierbabuena (Yerbabuena) (materias primas)	Kilogramo
1134	23100095	Jengibre (materias primas)	Kilogramo
1135	23100096	Manzanilla (materias primas)	Kilogramo
1136	23100097	Oregano (materias primas)	Kilogramo
1137	23100098	Pepita (materias primas)	Kilogramo
1138	23100099	Pistache (materias primas)	Kilogramo
1139	23100100	Saborizante  (materias primas)	Kilogramo
1140	23100101	Tomillo  (materias primas)	Kilogramo
1141	23100102	Tilapia	Kilogramo
1142	2320	Insumos textiles adquiridos como materia prima	
1143	23201	Insumos textiles adquiridos como materia prima	
1144	23200001	Acetato fibra corta	Pieza
1145	23200002	Acetato filamento continuo	Pieza
1146	23200003	Acrilicas (fibras)	Metro
1147	23200004	Algodon (natural)	Metro
1148	23200005	Borra	Kilogramo
1149	23200006	Cerda (sin preparar o hilar)	Metro
1150	23200007	Cuerdas	Metro
1151	23200008	Cuerdas de nylon para llantas	Metro
1152	23200009	Cuerdas de rayon para llantas	Metro
1153	23200010	Estambres	Metro
1154	23200011	Estopa	Kilogramo
1155	23200012	Guata	Metro Cuadrado
1156	23200013	Henequen (natural)	Metro
1157	23200014	Hilo de nylon industrial	Metro
1158	23200015	Hilo de rayon industrial	Metro
1159	23200016	Hilos de algodon	Metro
1160	23200017	Hilos de fibras artificiales	Metro
1161	23200018	Hilos de henequen	Metro
1162	23200019	Hilos de lana	Metro
1163	23200020	Lana (natural)	Kilogramo
1164	23200021	Lana (sin preparar o hilar)	Metro
1165	23200022	Manta de cielo	Metro Cuadrado
1166	23200023	Nylon	Metro
1167	23200024	Pelo (sin preparar o hilar)	Metro
1168	23200025	Pluma (sin preparar o hilar)	Metro
1169	23200026	Poliester (fibras)	Metro Cuadrado
1170	23200027	Rayon fibra corta	Metro Cuadrado
1171	23200028	Rayon filamento continuo	Metro
1172	23200029	Tela de algodon	Metro Cuadrado
1173	23200030	Tela de henequen	Metro Cuadrado
1174	23200031	Tela de lana	Metro Cuadrado
1175	23200032	Telas combinadas	Metro Cuadrado
1176	23200033	Telas de fibras artificiales	Metro Cuadrado
1177	23200034	Tintas para textiles	Litro
1178	23200035	Trapo	Metro Cuadrado
1179	23200036	Viscosa artificial	Metro Cuadrado
1180	23200037	Blonda	Metro Cuadrado
1181	23200038	Hilo cañamo	Metro
1182	23200039	Mecahilo	Metro
1183	23200040	Mecate	Metro
1184	23200041	Lana de vidrio	Metro
1185	2330	Productos de papel, carton e impresos adquiridos como materia prima	
1186	23301	Productos de papel, carton e impresos adquiridos como materia prima	
1187	23300001	Carton corrugado	Pieza
1188	23300002	Carton couche	Pieza
1189	23300003	Carton gris	Pieza
1190	23300004	Celulosa (materia prima vegetal)	Pieza
1191	23300005	Papel aluminio	Pieza
1192	2340	Combustibles, lubricantes, aditivos, carbon y sus derivados adquiridos como materia prima	
1193	23401	Combustibles, lubricantes, aditivos, carbon y sus derivados adquiridos como materia prima	
1194	23400001	Aguarras (materia prima vegetal)	Litro
1195	23400002	Brea o colofonia (materia prima vegetal)	Litro
1196	23400003	Ceras vegetales (materia prima vegetal)	Litro
1197	23400004	Oleorresina (materia prima vegetal)	Litro
1198	23400005	Trementina (materia prima vegetal)	Litro
1199	23400006	Viscosa (materia prima vegetal)	Litro
1200	2350	Productos quimicos, farmaceuticos y de laboratorio adquiridos como materia prima	
1201	23501	Productos quimicos, farmaceuticos y de laboratorio adquiridos como materia prima	
1202	23500001	Aceite de almendras dulces	Litro
1203	23500002	Ferricianuro	Litro
1204	23500003	Productos quimicos adquiridos como materia prima	Pieza
1205	23500004	Productos farmaceuticos adquiridos como materia prima	Pieza
1206	23500005	Productos de laboratorio adquiridos como materia prima	Pieza
1207	23500006	Productos derivados de la sangre	Pieza
1208	23500007	Productos medicos veterinarios	Pieza
1209	23500008	Pseudo aroma	Litro
1210	2360	Productos metalicos y a base de minerales no metalicos adquiridos como materia prima	
1211	23601	Productos metalicos y a base de minerales no metalicos adquiridos como materia prima	
1212	23600001	Aguja	Pieza
1213	23600002	Billet	Pieza
1214	23600003	Lingote	Pieza
1215	23600004	Productos metalicos adquiridos como materia prima	Pieza
1216	23600005	Productos a base de minerales no metalicos como materia prima	Pieza
1217	24400019	Cañas de madera	Pieza
1218	2370	Productos de cuero, piel, plastico y hule adquiridos como materia prima	
1219	23701	Productos de cuero, piel, plastico y hule adquiridos como materia prima	
1220	23700001	Arca, arcon, maleta	Pieza
1221	23700002	Asno (cueros y pieles sin preparar)	Pieza
1222	23700003	Bolsas de polietileno	Pieza
1223	23700004	Bolsas, saco o fundas de plastico	Pieza
1224	23700005	Bovino (cueros y pieles sin preparar)	Pieza
1225	23700006	Caballo (cueros y pieles sin preparar)	Pieza
1226	23700007	Cabra (cueros y pieles sin preparar)	Pieza
1227	23700008	Carnazas (cueros y pieles semipreparados)	Pieza
1228	23700009	Chinchilla (cueros y pieles sin preparar)	Pieza
1229	23700010	Conejo (cueros y pieles sin preparar)	Pieza
1230	23700011	Correas y bandas de transmision de hule	Pieza
1231	23700012	Correas y bandas transportadoras de hule	Pieza
1232	23700013	Curtidas o adobadas (cueros y pieles semipreparados)	Pieza
1233	23700014	Empaque de hule	Pieza
1234	23700015	Encalados (cueros y pieles semipreparados)	Pieza
1235	23700016	Gamuza (cueros y pieles semipreparados)	Pieza
1236	23700017	Hilos y cuerdas de hule natural vulcanizado	Metro
1237	23700018	Latex (materia prima vegetal)	Pieza
1238	23700019	Mula (cueros y pieles sin preparar)	Pieza
1239	23700020	Oveja (cueros y pieles sin preparar)	Pieza
1240	23700021	Pellejos (animal) (cueros y pieles sin preparar)	Pieza
1241	23700022	Piel de pez vela (cueros y pieles sin preparar)	Pieza
1242	23700023	Piel de tiburon (cueros y pieles sin preparar)	Pieza
1243	23700024	Pieles de gato (cueros y pieles sin preparar)	Pieza
1244	23700025	Pieles de pescado (cueros y pieles sin preparar)	Pieza
1245	23700026	Piquelados (cueros y pieles semipreparados)	Pieza
1246	23700027	Planchas, hojas y tiras de hule natural vulcanizado	Pieza
1247	23700028	Puerco (cueros y pieles sin preparar)	Pieza
1248	23700029	Salados (cueros y pieles semipreparados)	Pieza
1249	23700030	Secos (cueros y pieles semipreparados)	Pieza
1250	23700031	Tacones y suelas de hule	Pieza
1251	23700032	Vaqueta (cueros y pieles semipreparados)	Pieza
1252	23700033	Cajas de plastico	Pieza
1253	23700034	Envases de plastico	Pieza
1254	23700035	Rollos de polietileno	Pieza
1255	23700036	Tapas de plastico	Pieza
1256	23700037	Poliburbuja	Pieza
1257	23700038	Poliestrech	Pieza
1258	23700039	Espuma de poliuretano	Pieza
1259	23700040	Vinil adherible	Pieza
1260	23700041	Productos de acrilico	Pieza
1261	23700042	Productos de lona	Pieza
1262	23700043	Productos de poliamida (nylon)	Pieza
1263	23700044	Poliestireno	Pieza
1264	2380	Mercancias adquiridas para su comercializacion	
1265	23801	Mercancias para su comercializacion en tiendas del sector publico	
1266	23800001	Abulon preparado y enlatado (para su comercializacion)	Pieza
1267	23800002	Aceite vegetal comestible de ajonjoli (para su comercializacion)	Litro
1268	23800003	Aceite vegetal comestible de algodon (para su comercializacion)	Litro
1269	23800004	Aceite vegetal comestible de cartamo (para su comercializacion)	Litro
1270	23800005	Aceite vegetal comestible de oliva (para su comercializacion)	Litro
1271	23800006	Aceite vegetal comestible de soya (para su comercializacion)	Litro
1272	23800007	Aceitunas preparadas (para su comercializacion)	Kilogramo
1273	23800008	Agua purificada (para su comercializacion)	Litro
1274	23800009	Aguardientes (para su comercializacion)	Litro
1275	23800010	Aguas gaseosas (para su comercializacion)	Litro
1276	23800011	Almeja preparada y/o enlatada (para su comercializacion)	Pieza
1277	23800012	Almidon de maiz (para su comercializacion)	Kilogramo
1278	23800013	Ates de frutas (para su comercializacion)	Kilogramo
1279	23800014	Atun preparado y/o enlatado (para su comercializacion)	Pieza
1280	23800015	Azucar (para su comercializacion)	Kilogramo
1281	23800016	Bacalao preparado y/o enlatado (para su comercializacion)	Pieza
1282	23800017	Cafe molido (para su comercializacion)	Kilogramo
1283	23800018	Cafe soluble (para su comercializacion)	Kilogramo
1284	23800019	Cafe tostado (para su comercializacion)	Kilogramo
1285	23800020	Cajetas de leche (leche quemada) (para su comercializacion)	Kilogramo
1286	23800021	Calamar preparado y/o enlatado (para su comercializacion)	Pieza
1287	23800022	Camaron preparado y/o enlatado (para su comercializacion)	Pieza
1288	23800023	Cangrejo preparado y/o enlatado (para su comercializacion)	Pieza
1289	23800024	Caracol de mar preparado y/o enlatado (para su comercializacion)	Pieza
1290	23800025	Caramelos, bombones y confites (para su comercializacion)	Kilogramo
1291	23800026	Carne de asnal preparada y/o enlatada (para su comercializacion)	Pieza
1292	23800027	Carne de bovino preparada y/o enlatada (para su comercializacion)	Pieza
1293	23800028	Carne de caballar preparada y/o enlatada (para su comercializacion)	Pieza
1294	23800029	Carne de caprino preparada y/o enlatada (para su comercializacion)	Pieza
1295	23800030	Carne de gallina preparada y/o enlatada (para su comercializacion)	Pieza
1296	23800031	Carne de gallo preparada y/o enlatada (para su comercializacion)	Pieza
1297	23800032	Carne de ganso preparada y/o enlatada (para su comercializacion)	Pieza
1298	23800033	Carne de guajolote preparada y/o enlatada (para su comercializacion)	Pieza
1299	23800034	Carne de ovino preparada y/o enlatada (para su comercializacion)	Pieza
1300	56300127	Tirafondeadora con torquimetro	Pieza
1301	23800035	Carne de pato preparada y/o enlatada (para su comercializacion)	Pieza
1302	23800036	Carne de pollo preparada y/o enlatada (para su comercializacion)	Pieza
1303	23800037	Carne de porcino preparada y/o enlatada (para su comercializacion)	Pieza
1304	23800038	Carpa preparada y/o enlatada (para su comercializacion)	Pieza
1305	23800039	Cazon (tiburon) preparado y/o enlatado (para su comercializacion)	Pieza
1306	23800040	Cereales (para su comercializacion)	Kilogramo
1307	23800041	Cerveza (para su comercializacion)	Litro
1308	23800042	Charal preparado y/o enlatado (para su comercializacion)	Pieza
1309	23800043	Chicharron de camaron preparado y/o enlatado (para su comercializacion)	Pieza
1310	23800044	Chiles en conserva (para su comercializacion)	Kilogramo
1311	23800045	Chocolate de mesa (para su comercializacion)	Kilogramo
1312	23800046	Cigarrillos (para su comercializacion)	Pieza
1313	23800047	Consomes (para su comercializacion)	Litro
1314	23800048	Crema condensada (para su comercializacion)	Litro
1315	23800049	Crema en polvo (para su comercializacion)	Kilogramo
1316	23800050	Crema fresca (para su comercializacion)	Litro
1317	23800051	Embutidos de pollo y puerco (para su comercializacion)	Kilogramo
1318	23800052	Esencias y sabores (para su comercializacion)	Kilogramo
1319	23800053	Fecula de maiz (para su comercializacion)	Kilogramo
1320	23800054	Fecula de trigo (para su comercializacion)	Kilogramo
1321	23800055	Frituras (para su comercializacion)	Kilogramo
1322	23800056	Frutas congeladas (para su comercializacion)	Kilogramo
1323	23800057	Frutas en conserva (para su comercializacion)	Kilogramo
1324	23800058	Galletas (para su comercializacion)	Kilogramo
1325	23800059	Gelatina (para su comercializacion)	Kilogramo
1326	23800060	Guachinango preparado y/o enlatado (para su comercializacion)	Kilogramo
1327	23800061	Harina de arroz (para su comercializacion)	Kilogramo
1328	23800062	Harina de centeno (para su comercializacion)	Kilogramo
1329	23800063	Harina de frutas (para su comercializacion)	Kilogramo
1330	23800064	Harina de maiz (para su comercializacion)	Kilogramo
1331	23800065	Harina de soya (para su comercializacion)	Kilogramo
1332	23800066	Harina de trigo (para su comercializacion)	Kilogramo
1333	23800067	Harina de tuberculos (para su comercializacion)	Kilogramo
1334	23800068	Hielo y helados (para su comercializacion)	Pieza
1335	23800069	Jaiba preparada y/o enlatada (para su comercializacion)	Pieza
1336	23800070	Jarabe y mieles (para su comercializacion)	Litro
1337	23800071	Jugos de frutas envasados o enlatados (para su comercializacion)	Litro
1338	23800072	Juguetes de hule (para distribucion a la poblacion)	Pieza
1339	23800073	Juguetes de plastico	Pieza
1340	23800074	Langosta de mar preparada y/o enlatada (para su comercializacion)	Pieza
1341	23800075	Langostino preparado y/o enlatado (para su comercializacion)	Pieza
1342	23800076	Leche condensada (para su comercializacion)	Litro
1343	23800077	Leche en pastillas (para su comercializacion)	Pieza
1344	23800078	Leche en polvo (para su comercializacion)	Kilogramo
1345	23800079	Leche evaporada (para su comercializacion)	Litro
1346	23800080	Leche maternizada (para su comercializacion)	Litro
1347	23800081	Leche pasteurizada (para su comercializacion)	Litro
1348	23800082	Leche reconstituida (para su comercializacion)	Litro
1349	23800083	Levadura y polvos de hornear (para su comercializacion)	Kilogramo
1350	23800084	Manteca vegetal (para su comercializacion)	Kilogramo
1351	23800085	Mantequilla (para su comercializacion)	Kilogramo
1352	23800086	Margarina (para su comercializacion)	Kilogramo
1353	23800087	Mezcal y tequila (para su comercializacion)	Litro
1354	23800088	Mojarra preparada y/o enlatada (para su comercializacion)	Pieza
1355	23800089	Ostion preparado y/o enlatado (para su comercializacion)	Pieza
1356	23800090	Pan (blanco y de dulce) (para su comercializacion)	Pieza
1357	23800091	Pastas para sopas (para su comercializacion)	Kilogramo
1358	23800092	Pasteles (para su comercializacion)	Kilogramo
1359	23800093	Piloncillo (para su comercializacion)	Kilogramo
1360	23800094	Pulpo preparado y/o enlatado (para su comercializacion)	Kilogramo
1361	23800095	Puros (tabaco) (para su comercializacion)	Pieza
1362	23800096	Queso chihuahua (para su comercializacion)	Kilogramo
1363	23800097	Queso fresco (para su comercializacion)	Kilogramo
1364	23800098	Queso oaxaca (para su comercializacion)	Kilogramo
1365	23800099	Refresco (para su comercializacion)	Litro
1366	23800100	Requeson (para su comercializacion)	Kilogramo
1367	23800101	Robalo preparado y/o enlatado (para su comercializacion)	Kilogramo
1368	23800102	Sabalo preparado y/o enlatado (para su comercializacion)	Kilogramo
1369	23800103	Sal para uso alimenticio (para su comercializacion)	Kilogramo
1370	23800104	Salmon preparado y/o enlatado (para su comercializacion)	Pieza
1371	23800105	Sardina y macarela enlatada y/o preparada (para su comercializacion)	Pieza
1372	23800106	Suero de leche (para su comercializacion)	Litro
1373	23800107	Tortillas de harina (para su comercializacion)	Kilogramo
1374	23800108	Tortillas de maiz (para su comercializacion)	Kilogramo
1375	23800109	Verduras y legumbres en conserva (para su comercializacion)	Kilogramo
1376	23800110	Vinos y licores (para su comercializacion)	Litro
1377	23800111	Yogurts (para su comercializacion)	Litro
1378	23800112	Cafe instantaneo preparado (para su comercializacion)	Kilogramo
1379	23800113	Articulos promocionales (para su comercializacion en tiendas del sector publico)	Pieza
1380	23800114	Insumos para empaque y embalaje (para su comercializacion en tiendas del sector publico)	Pieza
1381	59101	Software	
1382	23800115	Acondicionador (para su comercializacion)	Pieza
1383	23800116	Adobos (para su comercializacion)	Pieza
1384	23800117	Cerillos (para su comercializacion)	Pieza
1385	23800118	Elote (para su comercializacion)	Kilogramo
1386	23800119	Encendedores (para su comercializacion)	Pieza
1387	23800120	Manteca (para su comercializacion)	Kilogramo
1388	23800121	Moles (para su comercializacion)	Kilogramo
1389	23800122	Papillas (para su comercializacion)	Pieza
1390	23800123	Popotes (para su comercializacion)	Kilogramo
1391	23800124	Postres en polvo (para su comercializacion)	Pieza
1392	23800125	Pure de tomate (para su comercializacion)	Pieza
1393	23800126	Semillas para cultivo (para su comercializacion)	Kilogramo
1394	23800127	Te (para su comercializacion)	Pieza
1395	23800128	Ungüentos y pomadas (para su comercializacion)	Pieza
1396	23800129	Velas, veladoras (para su comercializacion)	Pieza
1397	23800130	Libros (para su comercializacion)	Pieza
1398	2390	Otros productos adquiridos como materia prima	
1399	23901	Otros productos adquiridos como materia prima	
1400	23900001	Alfiletero	Pieza
1401	23900002	Bagazo de caña (materia prima vegetal)	Kilogramo
1402	23900003	Ceras de origen animal (productos animales)	Pieza
1403	23900004	Conchas (productos animales)	Pieza
1404	23900005	Conchas de abulon (productos animales)	Pieza
1405	23900006	Conchas de almeja (productos animales)	Pieza
1406	23900007	Conchas de caracol (productos animales)	Pieza
1407	23900008	Cuerno (productos animales)	Pieza
1408	23900009	Embrion (productos animales)	Pieza
1409	23900010	Estiercol (productos animales)	Kilogramo
1410	23900011	Gallinaza (productos animales)	Kilogramo
1411	23900012	Grasas de origen animal (productos animales)	Kilogramo
1412	23900013	Hiel (productos animales)	Kilogramo
1413	23900014	Hueso y productos (animales)	Kilogramo
1414	23900015	Mosco seco (productos animales)	Kilogramo
1415	23900016	Orina (productos animales)	Litro
1416	23900017	Polen (productos animales)	Kilogramo
1417	23900018	Tara (articulos para comercios)	Pieza
1418	23900019	Aceite de higado de tiburon	Litro
1419	23900020	Aceites de pescado	Litro
1420	23900021	Aleta tiburon	Kilogramo
1421	23900022	Alga marina	Kilogramo
1422	23900023	Anchoveta	Kilogramo
1423	23900024	Masas	Kilogramo
1424	23902	Petroleo, gas y sus derivados adquiridos como materia prima	
1425	23900100	Oxigeno industrial	Kilogramo
1426	23900101	Gas butano	Kilogramo
1427	23900102	Nitrogeno	Kilogramo
1428	23900103	Bioxido de carbono	Kilogramo
1429	23900104	Helio	Kilogramo
1430	2400	Materiales y articulos de construccion y de reparacion	
1431	2410	Productos minerales no metalicos	
1432	24101	Productos minerales no metalicos	
1433	24100001	Aluminio (mineral metalico no ferroso)	Kilogramo
1434	24100002	Anatasa (mineral metalico no ferroso)	Kilogramo
1435	24100003	Anglesita (mineral metalico no ferroso)	Kilogramo
1436	24100004	Antimonio (mineral metalico no ferroso)	Kilogramo
1437	24100005	Apatitos (mineral no metalico)	Kilogramo
1438	24100006	Arena (mineral no metalico)	Kilogramo
1439	24100007	Argirodita (mineral metalico no ferroso)	Kilogramo
1440	24100008	Arsenico (mineral no metalico)	Kilogramo
1441	24100009	Arsenolita (mineral no metalico)	Kilogramo
1442	24100010	Asbolita (mineral metalico no ferroso)	Kilogramo
1443	24100011	Azufre (mineral no metalico)	Kilogramo
1444	24100012	Azulejo	Kilogramo
1445	24100013	Azurita (mineral metalico no ferroso)	Kilogramo
1446	24100014	Baddeleyita (mineral metalico no ferroso)	Kilogramo
1447	24100015	Bario (mineral metalico no ferroso)	Kilogramo
1448	24100016	Barita (baritina) (mineral metalico no ferroso)	Kilogramo
1449	24100017	Bauxita (mineral metalico no ferroso)	Kilogramo
1450	24100018	Berilio (mineral metalico no ferroso)	Kilogramo
1451	24100019	Berilo (mineral metalico no ferroso)	Kilogramo
1452	24100020	Berzelianita (mineral no metalico)	Kilogramo
1453	24100021	Bismutina (mineral metalico no ferroso)	Kilogramo
1454	24100022	Bismutita (mineral metalico no ferroso)	Kilogramo
1455	24100023	Bismuto (mineral metalico no ferroso)	Kilogramo
1456	24100024	Blenda (mineral metalico no ferroso)	Kilogramo
1457	24100025	Blenda de manganeso (mineral metalico ferroso)	Kilogramo
1458	24100026	Boro (mineral no metalico)	Kilogramo
1459	24100027	Braunita (mineral metalico ferroso)	Kilogramo
1460	24100028	Bromo (mineral no metalico)	Kilogramo
1461	24100029	Brookita (mineral metalico no ferroso)	Kilogramo
1462	24100030	Cadmio (mineral metalico no ferroso)	Kilogramo
1463	24100031	Calamina (mineral metalico no ferroso)	Kilogramo
1464	24100032	Calcio (mineral no metalico)	Kilogramo
1465	24100033	Calcita (mineral no metalico)	Kilogramo
1466	24100034	Calcopirita (mineral metalico no ferroso)	Kilogramo
1467	24100035	Caliza (carbonato de calcio) (mineral no metalico)	Kilogramo
1468	24100036	Carbon (mineral metalico ferroso)	Kilogramo
1469	24100037	Carbono (mineral no metalico)	Kilogramo
1470	24100038	Carnotita (mineral metalico no ferroso)	Kilogramo
1471	24100039	Casiterita (mineral metalico no ferroso)	Kilogramo
1472	24100040	Cerio (mineral no metalico)	Kilogramo
1473	24100041	Cerosita (mineral metalico no ferroso)	Kilogramo
1474	24100042	Cesio (mineral metalico no ferroso)	Kilogramo
1475	24100043	Cinabrio (mineral metalico no ferroso)	Kilogramo
1476	24100044	Cincita (mineral metalico no ferroso)	Kilogramo
1477	24100045	Circon (mineral metalico no ferroso)	Kilogramo
1478	24100046	Circonio (mineral metalico no ferroso)	Kilogramo
1479	24100047	Cobaltina (mineral metalico no ferroso)	Kilogramo
1480	24100048	Cobalto (mineral metalico no ferroso)	Kilogramo
1481	24100049	Cobelita (mineral metalico no ferroso)	Kilogramo
1482	24100050	Cobre (mineral metalico no ferroso)	Kilogramo
1483	24100051	Colcosina (mineral metalico no ferroso)	Kilogramo
1484	24100052	Contra tanque bajo w.c.	Kilogramo
1485	24100053	Criolita (mineral metalico no ferroso)	Kilogramo
1486	24100054	Criolita (no metalica) (mineral no metalico)	Kilogramo
1487	24100055	Crocoita (mineral metalico no ferroso)	Kilogramo
1488	24100056	Cromila (mineral metalico no ferroso)	Kilogramo
1489	24100057	Cromita ferrosa (mineral metalico ferroso)	Kilogramo
1490	24100058	Cromo (mineral metalico no ferroso)	Kilogramo
1491	24100059	Cuarzo (mineral no metalico)	Kilogramo
1492	24100060	Cuprita (mineral metalico no ferroso)	Kilogramo
1493	24100061	Diamante (mineral no metalico)	Kilogramo
1494	24100062	Disprosio (mineral no metalico)	Kilogramo
1495	24100063	Dolomita (mineral metalico no ferroso)	Kilogramo
1496	24100064	Erbio (mineral metalico no ferroso)	Kilogramo
1497	24100065	Escandio (mineral no metalico)	Kilogramo
1498	24100066	Esmaltina (mineral metalico no ferroso)	Kilogramo
1499	24100067	Espato fluor (fluorita) (mineral no metalico)	Kilogramo
1500	24100068	Estaño (mineral metalico no ferroso)	Kilogramo
1501	24100069	Ferberita (mineral metalico no ferroso)	Kilogramo
1502	24100070	Fluor (mineral no metalico)	Kilogramo
1503	24100071	Fluoropatito (mineral no metalico)	Kilogramo
1504	24100072	Fosforita (mineral no metalico)	Kilogramo
1505	24100073	Fosforo (mineral no metalico)	Kilogramo
1506	24100074	Francio (mineral metalico no ferroso)	Kilogramo
1507	24100075	Galena (mineral metalico no ferroso)	Kilogramo
1508	24100076	Galio (mineral no metalico)	Kilogramo
1509	24100077	Garnierita (mineral metalico no ferroso)	Kilogramo
1510	24100078	Germanio (mineral metalico no ferroso)	Kilogramo
1511	24100079	Grafito (mineral no metalico)	Kilogramo
1512	24100080	Granito (mineral no metalico)	Kilogramo
1513	24100081	Grava (mineral no metalico)	Kilogramo
1514	24100082	Greenockita (mineral metalico no ferroso)	Kilogramo
1515	24100083	Hasmanita (mineral metalico ferroso)	Kilogramo
1516	24100084	Hatnio (mineral metalico no ferroso)	Kilogramo
1517	24100085	Helmio (mineral no metalico)	Kilogramo
1518	24100086	Hematita (mineral metalico ferroso)	Kilogramo
1519	24100087	Heterogenita (mineral metalico no ferroso)	Kilogramo
1520	24100088	Hierro (mineral metalico ferroso)	Kilogramo
1521	24100089	Hubnerita (mineral metalico no ferroso)	Kilogramo
1522	24100090	Ilmenita (mineral metalico no ferroso)	Kilogramo
1523	24100091	Iridio (mineral metalico no ferroso)	Kilogramo
1524	24100092	Iterbio (mineral no metalico)	Kilogramo
1525	24100093	Itrio (mineral metalico no ferroso)	Kilogramo
1526	24100094	Ladrillos de arcilla	Pieza
1527	24100095	Ladrillos refractarios de arcilla	Pieza
1528	24100096	Lantano (mineral metalico no ferroso)	Kilogramo
1529	24100097	Libre (mineral no metalico)	Kilogramo
1530	24100098	Limonita (mineral metalico ferroso)	Kilogramo
1531	24100099	Litio (mineral metalico no ferroso)	Kilogramo
1532	24100100	Lutesio (mineral no metalico)	Kilogramo
1533	24100101	Magnesio (mineral metalico no ferroso)	Kilogramo
1534	24100102	Magnesita (mineral metalico no ferroso)	Kilogramo
1535	24100103	Magnetita (mineral metalico ferroso)	Kilogramo
1536	24100104	Malaquita (mineral metalico no ferroso)	Kilogramo
1537	24100105	Manganeso (mineral metalico ferroso)	Kilogramo
1538	24100106	Manganita (mineral metalico ferroso)	Kilogramo
1539	24100107	Mercurio (mineral metalico no ferroso)	Kilogramo
1540	24100108	Minerales de azufre (mineral no metalico)	Kilogramo
1541	24100109	Minerales de bromo (mineral no metalico)	Kilogramo
1542	24100110	Molibdenita (mineral metalico no ferroso)	Kilogramo
1543	24100111	Molibdeno (mineral metalico no ferroso)	Kilogramo
1544	24100112	Monacita (mineral metalico no ferroso)	Kilogramo
1545	24100113	Mosaicos y zoclos de arcilla	Pieza
1546	24100114	Nativo (mineral metalico no ferroso)	Kilogramo
1547	24100115	Nativo (mineral no metalico)	Kilogramo
1548	24100116	Naumanita (mineral no metalico)	Kilogramo
1549	24100117	Niobio (mineral metalico no ferroso)	Kilogramo
1550	24100118	Niquel (mineral metalico no ferroso)	Kilogramo
1551	24100119	Niquelina (mineral metalico no ferroso)	Kilogramo
1552	24100120	Olivino (mineral metalico no ferroso)	Kilogramo
1553	24100121	Oro (metal precioso)	Kilogramo
1554	24100122	Oropimente (mineral no metalico)	Kilogramo
1555	24100123	Osmio (mineral metalico no ferroso)	Kilogramo
1556	24100124	Oxigeno (mineral no metalico)	Kilogramo
1557	24100125	Paladio (mineral metalico no ferroso)	Kilogramo
1558	24100126	Parafina	Kilogramo
1559	24100127	Pechblenda (mineral metalico no ferroso)	Kilogramo
1560	24100128	Piedra cantera (mineral no metalico)	Kilogramo
1561	24100129	Pirita (mineral metalico ferroso)	Kilogramo
1562	24100130	Pirita magnetica (mineral metalico no ferroso)	Kilogramo
1563	24100131	Plata (metal precioso)	Kilogramo
1564	24100132	Platino (metal precioso)	Kilogramo
1565	24100133	Plomo (mineral metalico no ferroso)	Kilogramo
1566	24100134	Porfido (mineral no metalico)	Kilogramo
1567	24100135	Potasio (mineral metalico no ferroso)	Kilogramo
1568	24100136	Praseodimio (mineral metalico no ferroso)	Kilogramo
1569	24100137	Puzolana	Kilogramo
1570	24100138	Radio (mineral metalico no ferroso)	Kilogramo
1571	24100139	Rejalgar (mineral no metalico)	Kilogramo
1572	24100140	Renio (mineral metalico no ferroso)	Kilogramo
1573	24100141	Rodio (mineral metalico no ferroso)	Kilogramo
1574	24100142	Rubidio (mineral metalico no ferroso)	Kilogramo
1575	24100143	Rutenio (mineral metalico no ferroso)	Kilogramo
1576	24100144	Rutilio (mineral metalico no ferroso)	Kilogramo
1577	24100145	Samano (mineral metalico no ferroso)	Kilogramo
1578	24100146	Scheelita (mineral metalico no ferroso)	Kilogramo
1579	24100147	Selenio (mineral no metalico)	Kilogramo
1580	24100148	Serpentina (mineral metalico no ferroso)	Kilogramo
1581	24100149	Siderita (mineral metalico ferroso)	Kilogramo
1582	24100150	Silicio (mineral no metalico)	Kilogramo
1583	24100151	Smithsonita (mineral metalico no ferroso)	Kilogramo
1584	24100152	Sodio (mineral metalico no ferroso)	Kilogramo
1585	24100153	Tabique comun recocido de arcilla	Pieza
1586	24100154	Tabiques de cemento y arena (tabicon)	Pieza
1587	24100155	Tabiques refractarios de arcilla	Pieza
1588	24100156	Talio (mineral metalico no ferroso)	Kilogramo
1589	24100157	Tejas y terrazos de arcilla	Pieza
1590	24100158	Terbio (mineral no metalico)	Kilogramo
1591	24100159	Tezontle (mineral no metalico)	Kilogramo
1592	24100160	Tiemanita (mineral no metalico)	Kilogramo
1593	24100161	Titanio (mineral metalico no ferroso)	Kilogramo
1594	24100162	Torianita (mineral metalico no ferroso)	Kilogramo
1595	24100163	Torio (mineral metalico no ferroso)	Kilogramo
1596	24100164	Torita (mineral metalico no ferroso)	Kilogramo
1597	24100165	Tulio (mineral no metalico)	Kilogramo
1598	24100166	Uranio (mineral metalico no ferroso)	Kilogramo
1599	24100167	Uranotorita (mineral metalico no ferroso)	Kilogramo
1600	24100168	Uropio (mineral metalico no ferroso)	Kilogramo
1601	24100169	Vanadio (mineral metalico no ferroso)	Kilogramo
1602	24100170	Vulfenita (mineral metalico no ferroso)	Kilogramo
1603	24100171	Witherita (mineral metalico no ferroso)	Kilogramo
1604	24100172	Wolframio (tungsteno) (mineral metalico no ferroso)	Kilogramo
1605	24100173	Wolframita (mineral metalico no ferroso)	Kilogramo
1606	24100174	Yeso (mineral no metalico)	Kilogramo
1607	24100175	Yodo (mineral no metalico)	Kilogramo
1608	24100176	Zinc (mineral metalico no ferroso)	Kilogramo
1609	24100179	Losas, losetas y mosaicos	Pieza
1610	24100180	Marmoles	Pieza
1611	24100182	Mosaicos	Pieza
1612	24100184	Terrazos	Pieza
1613	2420	Cemento y productos de concreto	
1614	24201	Cemento y productos de concreto	
1615	24200001	Aislantes para tuberia de asbesto-cemento	Metro
1616	24200002	Asfalto fmo	Metro Cuadrado
1617	24200003	Asfalto fri	Metro Cuadrado
1618	24200004	Asfalto fro	Metro Cuadrado
1619	24200005	Asfalto oxidado	Metro Cuadrado
1620	24200006	Asfalto puro	Metro Cuadrado
1621	24200007	Blocks de concreto	Pieza
1622	24200008	Cemento de escoria	Kilogramo
1623	24200009	Cemento tipo I	Kilogramo
1624	24200010	Cemento tipo II	Kilogramo
1625	24200011	Cemento tipo III	Kilogramo
1626	24200012	Cemento tipo IV	Kilogramo
1627	24200013	Cemento tipo V	Kilogramo
1628	24200014	Concreto aislante	Metro Cubico
1629	24200015	Concreto asfaltico	Metro Cubico
1630	24200016	Concreto premezclado	Metro Cubico
1631	24200017	Concreto refractario	Metro Cubico
1632	24200018	Durmientes de concreto	Pieza
1633	24200019	Emulsion asfaltica	Litro
1634	24200020	Ladrillos de concreto	Pieza
1635	24200021	Lamina de asbesto-cemento	Pieza
1636	24200022	Lamina de concreto	Pieza
1637	24200023	Losas o losetas de concreto	Pieza
1638	24200024	Mortero	Kilogramo
1639	24200025	Postes de concreto	Pieza
1640	24200026	Recipientes de asbesto-cemento	Pieza
1641	24200027	Recipientes de concreto	Pieza
1642	24200028	Tetrapodos de concreto	Pieza
1643	24200029	Tuberia y accesorios de asbesto-cemento	Metro
1644	24200030	Tuberia y accesorios de concreto	Metro
1645	24200031	Vigas y pilotes de concreto	Pieza
1646	2430	Cal, yeso y productos de yeso	
1647	24301	Cal, yeso y productos de yeso	
1648	24300001	Cal	Kilogramo
1649	24300002	Tabla roca (Tabla-yeso)	Pieza
1650	2440	Madera y productos de madera	
1651	24401	Madera y productos de madera	
1652	24400001	Carbon vegetal	Pieza
1653	24400002	Centro de trozas de madera	Pieza
1654	24400003	Cimbras (productos de madera)	Pieza
1655	24400004	Cortos de madera (productos de madera)	Pieza
1656	24400005	Costera de madera	Pieza
1657	24400006	Crucetas de madera (productos de madera)	Pieza
1658	24400007	Cuadrado aserrado labrado( productos de madera)	Pieza
1659	24400008	Cuadrado aserrado para reaserrar (productos de madera)	Pieza
1660	24400009	Duelas machihembradas (productos de madera)	Pieza
1661	24400010	Duelas para tonel (productos de madera)	Pieza
1662	24400011	Durmiente aserrado (productos de madera)	Pieza
1663	24400012	Durmiente labrado (productos de madera)	Pieza
1664	24400013	Durmiente preservado (productos de madera)	Pieza
1665	24400014	Leña en raja para papel	Pieza
1666	24400015	Tallos de palma	Pieza
1667	24400016	Trozas para chapas de madera	Pieza
1668	24400017	Varas para escoba y otros usos	Pieza
1669	24400018	Brazuelo de madera	Pieza
1670	24400020	Cedro	Pieza
1671	24400021	Roble	Pieza
1672	24400022	Astilla para celulosa	Pieza
1673	24400023	Briqueta para astilla	Pieza
1674	24400024	Empaques y embalajes	Pieza
1675	24400025	Envases, cajas	Pieza
1676	24400026	Fajilla de madera	Pieza
1677	24400027	Fibracel	Pieza
1678	24400028	Flitche aserrado	Pieza
1679	24400029	Hormas de madera	Pieza
1680	24400030	Juego de cambios aserrado o labrado	Pieza
1681	24400031	Madera para carroceria	Pieza
1682	24400032	Mangos y cabos de madera para herramienta	Pieza
1683	24400033	Moldura de madera	Pieza
1684	24400034	Palillos	Pieza
1685	24400035	Palos para escoba	Pieza
1686	24400036	Recorte de madera	Pieza
1687	24400037	Tabletas de madera	Pieza
1688	24400038	Tacones de madera	Pieza
1689	24400039	Tiras de madera	Pieza
1690	24400040	Tutores o rodrigones	Pieza
1691	24400041	Morillo (productos de madera)	Pieza
1692	24400042	Morillos de madera	Pieza
1693	24400043	Pilotes para mina de madera	Pieza
1694	24400044	Polines aserrado o labrado (productos de madera)	Pieza
1695	24400045	Postes de madera (productos de madera)	Pieza
1696	24400046	Postes de madera para linea de transmision	Pieza
1697	24400047	Postes para cerca de madera	Pieza
1698	24400048	Postes para telefono de madera	Pieza
1699	24400049	Tablas y tablones aserrados o labrados (productos de madera)	Pieza
1700	24400050	Tarimas (productos de madera)	Pieza
1701	24400051	Aserrin	Kilogramo
1702	2450	Vidrio y productos de vidrio	
1703	24501	Vidrio y productos de vidrio	
1704	24500001	Cristal escritorio	Metro Cuadrado
1705	24500002	Cristal flotado	Metro Cuadrado
1706	24500003	Cristal refractario	Metro Cuadrado
1707	24500004	Lupas	Pieza
1708	24500005	Vidrio curvo laminado	Metro Cuadrado
1709	24500006	Vidrio curvo templado	Metro Cuadrado
1710	24500007	Vidrio de bloque	Metro Cuadrado
1711	24500008	Vidrio optico	Metro Cuadrado
1712	24500009	Vidrio plano esmerilado y opaco	Metro Cuadrado
1713	24500010	Vidrio plano labrado	Metro Cuadrado
1714	24500011	Vidrio plano liso	Metro Cuadrado
1715	24500012	Vidrio plano templado	Metro Cuadrado
1716	2460	Material electrico y electronico	
1717	24601	Material electrico y electronico	
1718	24600001	Acrilico (cubierta para lampara de tubos fluorescente)	Metro Cuadrado
1719	24600002	Acumuladores	Pieza
1720	24600003	Adaptadores	Pieza
1721	24600004	Aisladores electricos	Pieza
1722	24600005	Aislantes electricos	Pieza
1723	24600006	Alambres conductores	Metro
1724	24600007	Arnes electrico	Pieza
1725	24600008	Arrancador magnetico	Pieza
1726	24600009	Articulos para señalizacion	Pieza
1727	24600010	Atenuador electrico	Pieza
1728	24600011	Banda proyector	Pieza
1729	24600012	Base enchufe	Pieza
1730	24600013	Base lampara gas neon	Pieza
1731	24600014	Bobina inductora	Pieza
1732	24600015	Boquilla electrica	Pieza
1733	24600016	Bulbo	Pieza
1734	24600017	Cable de interconexion	Metro
1735	24600018	Cable de plastico	Metro
1736	24600019	Cables	Metro
1737	24600020	Cables conductores	Metro
1738	24600021	Caja registro (corriente electrica)	Pieza
1739	24600022	Capacitor	Pieza
1740	24600023	Carbones marcha alternador	Pieza
1741	24600024	Celda fotoelectrica	Pieza
1742	24600025	Centro distribucion dispositivos tableros electricos	Pieza
1743	24600026	Chasis aparato electronico	Pieza
1744	24600027	Cinta de aislar	Pieza
1745	24600028	Cinturon de pilas	Pieza
1746	24600029	Clavija electrica	Pieza
1747	24600030	Condensador electrico	Pieza
1748	24600031	Conectores	Pieza
1749	24600032	Contacto magnetico	Pieza
1750	24600033	Contacto multiple	Pieza
1751	24600034	Desconectador fusibles	Pieza
1752	24600035	Diadema telefonista	Pieza
1753	24600036	Diodo electrico	Pieza
1754	24600037	Dispositivos para instalaciones electricas	Pieza
1755	24600038	Electrodos	Pieza
1756	24600039	Eliminador bateria	Pieza
1757	24600040	Empalme electrico	Pieza
1758	24600041	Enchufe alimentacion canales	Pieza
1759	24600042	Enchufe electrico	Pieza
1760	24600043	Enlazador telefonico	Pieza
1761	24600044	Faroles	Pieza
1762	24600045	Filtro portadora	Pieza
1763	24600046	Focos	Pieza
1764	24600047	Fusibles	Pieza
1765	24600048	Guia onda	Pieza
1766	24600049	Iluminador discos	Pieza
1767	24600050	Iman para orientar muestras en campo magnetico	Pieza
1768	24600051	Interruptores	Pieza
1769	24600052	Lampara indicadora entrada llamada telefono	Pieza
1770	24600053	Lampara minera	Pieza
1771	24600054	Lamparas electricas	Pieza
1772	24600056	Linterna	Pieza
1773	24600057	Luminaria	Pieza
1774	24600058	Magneta telegrafica	Pieza
1775	24600059	Panel para el estudio de un receptor	Pieza
1776	24600060	Panel para instalar equipos electronicos	Pieza
1777	24600061	Pantalla lampara	Pieza
1778	24600062	Parrilla electrica	Pieza
1779	24600063	Pastillas (sonido)	Pieza
1780	24600064	Pilas	Pieza
1781	24600065	Pilas (baterias)	Pieza
1782	24600066	Placa enchufe	Pieza
1783	24600067	Porta fusibles	Pieza
1784	24600068	Protector de camara de vigilancia (carcaza)	Pieza
1785	24600069	Relevo electrico	Pieza
1786	24600070	Resistencia electrica	Pieza
1787	24600071	Seguro de sobrecarga para plastografo	Pieza
1788	24600072	Seguro de sobrepresion (evita presion excesiva dentro del extrusor)	Pieza
1789	24600073	Sensor de precision de vacio	Pieza
1790	24600074	Sensor para vacio tipo penning	Pieza
1791	24600075	Sensor para vacio tipo pirani	Pieza
1792	24600076	Separador magnetico	Pieza
1793	24600077	Socket o receptaculo	Pieza
1794	24600078	Soldadura (cobre, estaño, bronce, plomo, etc.)	Pieza
1795	24600079	Terminal electrica	Pieza
1796	24600080	Termistor (medidor de temperatura en medios gaseosos o liquidos)	Pieza
1797	24600081	Timbre o zumbador	Pieza
1798	24600082	Transistor	Pieza
1799	24600083	Tubo cuarzo	Pieza
1800	24600084	Tubo fluorescente	Pieza
1801	24600085	Tubo neon	Pieza
1802	24600086	Varilla para tierra (instalaciones electricas)	Pieza
1803	24600087	Bobina deflectora (juego de)	Pieza
1804	24600088	Pertiga telescopica	Pieza
1805	24600089	Sensor electrico	Pieza
1806	24600090	Apagador	Pieza
1807	24600091	Balastra	Pieza
1808	24600092	Caimanes	Pieza
1809	24600093	Clavijas	Pieza
1810	24600094	Extension electrica	Pieza
1811	24600095	Fotocelda	Pieza
1812	24600096	Foto lampara	Pieza
1813	24600098	Multicontacto	Pieza
1814	24600099	Placa	Pieza
1815	24600100	Roseta	Pieza
1816	24600101	Serie de luces	Pieza
1817	24600102	Lampara de leds	Pieza
1818	24600103	Lampara de emergencia recargable	Pieza
1819	24600104	Cincho	Pieza
1820	24600105	Cinta preventiva	Pieza
1821	24600106	Elemento termoelectrico (semiconductor)	Pieza
1822	24600107	Actuador electrico (motor)	Pieza
1823	24600108	Fotodetector	Pieza
1824	24600109	Componentes electronicos (regulador de tension ajustable, potenciometro, amplificador operacional, etc.)	Pieza
1825	24600110	Motor cd	Pieza
1826	24600111	Portaled	Pieza
1827	24600112	Sensor de presion	Pieza
1828	24600113	Material para canalizacion	Pieza
1829	24600114	Material electrico y electronico para aeronaves	Pieza
1830	24600115	Auriculares	Pieza
1831	24600116	Control digital de temperatura	Pieza
1832	24600117	Tarjeta de entrada-salida electronica	Pieza
1833	24600118	Controlador de potencia	Pieza
1834	2470	Articulos metalicos para la construccion	
1835	24701	Articulos metalicos para la construccion	
1836	24700001	Abrazaderas metalicas para tuberia	Pieza
1837	24700002	Adaptadores metalicos para tuberia	Pieza
1838	24700003	Alambre	Kilogramo
1839	24700004	Alambre desnudo de acero	Kilogramo
1840	24700005	Alambre desnudo de hierro	Kilogramo
1841	24700006	Alambre para construccion	Kilogramo
1842	24700007	Alambre para preesfuerzo	Kilogramo
1843	24700008	Alambre recocido	Kilogramo
1844	24700009	Alambre revestido	Kilogramo
1845	24700010	Alambron	Kilogramo
1846	24700011	Aleaciones de aluminio	Kilogramo
1847	24700012	Aleaciones de cobre	Kilogramo
1848	24700013	Aleaciones de niquel	Kilogramo
1849	24700014	Aleaciones de plomo	Kilogramo
1850	24700015	Angulos y soleras de hierro y acero	Pieza
1851	24700016	Balastra (reactor)	Pieza
1852	24700017	Barras huecas de acero inoxidable	Pieza
1853	24700018	Barras huecas de hierro y acero	Pieza
1854	24700019	Barras macizas de acero inoxidable	Pieza
1855	24700020	Barras macizas de hierro y acero	Pieza
1856	24700021	Bloques	Pieza
1857	24700022	Bloques de hierro y acero	Pieza
1858	24700023	Bridas metalicas para tuberia	Pieza
1859	24700024	Broca	Pieza
1860	24700025	Cables de hierro y acero	Metro
1861	24700026	Canceleria (productos de madera)	Pieza
1862	24700027	Cano desagüe	Pieza
1863	24700028	Codos metalicos para tuberia	Pieza
1864	24700029	Coples metalicos para tuberia	Pieza
1865	24700030	Cruces metalicas para tuberia	Pieza
1866	24700031	Desbastes de hierro y acero	Pieza
1867	24700032	Estructuras metalicas	Pieza
1868	24700033	Ferro manganeso	Kilogramo
1869	24700034	Ferro silicio	Kilogramo
1870	24700035	Ferro-aleaciones	Kilogramo
1871	24700036	Ferrocromo	Kilogramo
1872	24700037	Ferrofosforo	Kilogramo
1873	24700038	Ferromolibdeno	Kilogramo
1874	24700039	Ferroniquel	Kilogramo
1875	24700040	Fibra de vidrio	Metro Cuadrado
1876	24700041	Fierro gris	Pieza
1877	24700042	Flejes de hierro y acero	Pieza
1878	24700043	Galapagos (producto de industrias metalicas)	Pieza
1879	24700044	Herraje	Pieza
1880	24700045	Hierro o acero esponjoso	Kilogramo
1881	24700046	Hilos de asbesto	Metro
1882	24700047	Hilos, telas y cintas de asbesto	Metro
1883	24700048	Hojalata	Pieza
1884	24700049	Iman	Pieza
1885	24700050	Juntas de expansion metalicas para tuberia	Pieza
1886	24700052	Lamina de acero	Pieza
1887	24700053	Lamina de acero acabado en caliente	Pieza
1888	24700054	Lamina de acero acabado en frio	Pieza
1889	24700055	Lamina galvanizada	Pieza
1890	24800022	Triplay de pino	Pieza
1891	24700056	Laminacion primaria de hierro y acero	Pieza
1892	24700057	Laminas de acero	Pieza
1893	24700058	Laminas de hierro y acero	Pieza
1894	24700064	Malla de acero	Metro Cuadrado
1895	24700067	Manufacturas primarias de aluminio	Pieza
1896	24700068	Manufacturas primarias de bronce	Pieza
1897	24700069	Manufacturas primarias de cobre	Pieza
1898	24700070	Manufacturas primarias de estaño	Pieza
1899	24700071	Manufacturas primarias de laton	Pieza
1900	24700072	Manufacturas primarias de plomo	Pieza
1901	24700073	Manufacturas primarias de zinc	Pieza
1902	24700079	Niples metalicos para tuberia	Pieza
1903	24700080	Palanquilla de hierro y acero	Pieza
1904	24700081	Perfiles de acero inoxidable	Pieza
1905	24700082	Perfiles de hierro y acero	Pieza
1906	24700083	Perfiles tubulares	Pieza
1907	24700085	Placas de acero inoxidable	Pieza
1908	24700086	Planchas de hierro y acero	Pieza
1909	24700087	Plomo afinado	Kilogramo
1910	24700089	Polvo de hierro y acero	Kilogramo
1911	24700092	Postes metalicos	Pieza
1912	24700096	Puertas metalicas	Pieza
1913	24700097	Reducciones metalicas para tuberia	Pieza
1914	24700099	Rodillos de hierro y acero	Pieza
1915	24700100	Rondana	Pieza
1916	24700101	Soportes metalicos para tuberia	Pieza
1917	24700104	Tanques metalicos	Pieza
1918	24700105	Tapones metalicos para tuberia	Pieza
1919	24700107	Tela (rejilla) alambre	Metro Cuadrado
1920	24700108	Telas de asbesto	Metro Cuadrado
1921	24700111	Tes metalicas para tuberia	Pieza
1922	24700115	Tochos de acero	Pieza
1923	24700116	Tochos para fundicion	Pieza
1924	24700117	Tornillo	Pieza
1925	24700118	Torre receptora (estructura-antena)	Pieza
1926	24700119	Torres metalicas	Pieza
1927	24700123	Tubo conduccion gases	Pieza
1928	24700124	Tubo conduccion liquidos	Pieza
1929	24700125	Tubo ornamentacion	Pieza
1930	24700126	Tubos de acero	Pieza
1931	24700127	Tubos de acero autentico sin costura	Pieza
1932	24700128	Tubos de acero bajo carbon sin costura	Pieza
1933	24700129	Tubos de acero inoxidable	Pieza
1934	24700130	Tubos de acero medio carbon sin costura	Pieza
1935	24700131	Tubos de acero negro sin costura	Pieza
1936	24700132	Tubos de aluminio	Pieza
1937	24700133	Tubos de bronce o laton	Pieza
1938	24700134	Tubos de cobre	Pieza
1939	24700135	Tubos de hierro fundido con costura	Pieza
1940	24700136	Tubos de plomo	Pieza
1941	24700137	Tubos galvanizados	Pieza
1942	24700138	Tuerca	Pieza
1943	24700139	Tuerca de union para tuberia	Pieza
1944	24700141	Valvulas con mando neumatico impulsoras	Pieza
1945	24700142	Valvulas de asiento de 3 o mas vias	Pieza
1946	24700143	Valvulas de compuerta	Pieza
1947	24700144	Valvulas de control hidraulico	Pieza
1948	24700145	Valvulas de diafragma	Pieza
1949	24700146	Valvulas de engranes	Pieza
1950	24700147	Valvulas de expansion termostaticas	Pieza
1951	24700148	Valvulas de funcionamiento automatico	Pieza
1952	24700149	Valvulas de globo	Pieza
1953	24700150	Valvulas de inyeccion para compresoras	Pieza
1954	24700151	Valvulas de mariposa	Pieza
1955	24700152	Valvulas de piston de mas de 3 vias	Pieza
1956	24700153	Valvulas de retencion de aire	Pieza
1957	24700154	Valvulas de seguridad	Pieza
1958	24700155	Valvulas de tipo angulo	Pieza
1959	24700156	Valvulas de vastago deslizable	Pieza
1960	24700157	Valvulas electronicas	Pieza
1961	24700158	Valvulas macho (tapon y esfericas)	Pieza
1962	24700159	Valvulas neumaticas	Pieza
1963	24700161	Valvulas reductoras de presion	Pieza
1964	24700162	Varilla corrugada	Pieza
1965	24700164	Ventanas metalicas	Pieza
1966	24700166	Yes metalicas para tuberia	Pieza
1967	24700167	Zinc afinado	Pieza
1968	24700168	Billet	Pieza
1969	24700169	Lingotes	Pieza
1970	24700170	Abrazaderas	Pieza
1971	24700171	Anclas de mariposa	Pieza
1972	24700172	Clavo de concreto	Kilogramo
1973	24700173	Prisioneros	Pieza
1974	24700174	Tornillo con tuerca	Pieza
1975	24700175	Coladera	Pieza
1976	2480	Materiales complementarios	
1977	24801	Materiales complementarios	
1978	24800001	Alambre de puas	Metro
1979	24800002	Alfombras	Metro Cuadrado
1980	24800003	Chapas de madera	Metro
1981	24800004	Chapas y contrachapas de madera	Metro
1982	24800005	Cintas de asbesto	Metro
1983	24800006	Contrachapas de madera	Metro
1984	24800007	Cortinas de material natural	Metro Cuadrado
1985	24800008	Cortinas de plastico	Metro Cuadrado
1986	24800009	Cortinas de tela	Metro Cuadrado
1987	24800010	Cortinero	Pieza
1988	24800011	Laminas acanaladas de carton	Pieza
1989	24800012	Lonas	Metro Cuadrado
1990	24800013	Marco de madera	Pieza
1991	24800014	Persianas	Metro Cuadrado
1992	24800015	Pisos de hule (linoleo, losa, loseta)	Metro Cuadrado
1993	24800016	Sacos y costales	Pieza
1994	24800017	Tapetes	Pieza
1995	24800018	Tapices para pared	Metro Cuadrado
1996	24800019	Tapices para suelo	Metro Cuadrado
1997	24800020	Triplay de caoba	Pieza
1998	24800021	Triplay de cedro	Pieza
1999	24800023	Cinta adhesiva antiderrapante o antideslizante	Pieza
2000	24800024	Arbol ( de ornato)	Pieza
2001	24800025	Planta (de ornato)	Pieza
2002	24800026	Lambrin (productos de madera)	Pieza
2003	24800027	Laminas de plastico	Pieza
2004	24800028	Luna	Pieza
2005	24800029	Mallas de plastico	Pieza
2006	24800030	Puertas de madera	Pieza
2007	24800031	Telas de plastico	Metro Cuadrado
2008	24800032	Tuberia conduit y sus accesorios	Metro
2009	24800033	Tuberia y accesorios de asbesto	Metro
2010	24800034	Tuberias pvc	Metro
2011	24800035	Valvulas pvc	Metro
2012	24800036	Ventanas de madera	Pieza
2013	24800037	Vigas aserrada o labrada (productos de madera)	Pieza
2014	24800038	Mangueras y accesorios de plastico	Metro
2015	24800039	Acrilicos	Metro Cuadrado
2016	24800040	Alambre galvanizado	Pieza
2017	24800042	Perfacinta	Pieza
2018	24800043	Plafon	Metro Cuadrado
2019	24800045	Lavabo	Pieza
2020	24800046	Lavamanos	Pieza
2021	24800047	Mingitorio	Pieza
2022	24800048	Retrete (taza de baño, inodoro, w.c.)	Pieza
2023	24800049	Tina baño	Pieza
2024	24800050	Tina de polietileno	Pieza
2025	24800051	Tinaco de polietileno	Pieza
2026	24800053	Barreras absorbentes	Pieza
2027	24800054	Ventilador portatil	Pieza
2028	24800055	Cambiador de pañal	Pieza
2029	24800056	Señalamientos (proteccion civil, seguridad, etc.)	Pieza
2030	24800057	Piso laminado	Pieza
2031	24800058	Accesorios de tapiceria	Pieza
2032	24800059	Accesorios para persianas o cortinas	Pieza
2033	24800060	Cortina metalica (aluminio, acero, etc.)	Pieza
2034	24800061	Caballete para lamina	Pieza
2035	2490	Otros materiales y articulos de construccion y reparacion	
2036	24901	Otros materiales y articulos de construccion y reparacion	
2037	24900001	Barnices aislantes	Litro
2038	24900002	Barnices industriales	Litro
2039	24900003	Barnices para muebles	Litro
2040	24900004	Barnices para pisos	Litro
2041	24900005	Blanco de españa	Litro
2042	24900006	Cinta de teflon	Pieza
2043	24900007	Colorantes azoicos	Litro
2044	24900008	Colorantes de azufre	Litro
2045	24900009	Colorantes de origen vegetal	Litro
2046	24900010	Colorantes organicos sinteticos	Litro
2047	24900011	Conexiones y accesorios para tuberias pvc	Pieza
2048	24900012	Curtientes sinteticos	Litro
2049	24900013	Curtientes vegetales	Litro
2050	24900014	Esmaltes automotrices	Litro
2051	24900015	Esmaltes domesticos	Litro
2052	24900016	Esmaltes industriales	Litro
2053	24900017	Esmaltes marinos	Litro
2054	24900018	Esmaltes para aviones	Litro
2055	24900019	Impermeabilizantes	Litro
2056	24900020	Irrigador jardin	Pieza
2057	24900021	Lacas automotivas	Litro
2058	24900022	Lacas especiales para aviones	Litro
2059	24900023	Lacas industriales	Litro
2060	24900024	Lija	Pieza
2061	24900025	Mastique	Kilogramo
2062	24900026	Pegamentos	Litro
2063	24900027	Pigmentos casi neutros	Litro
2064	24900028	Pigmentos inorganicos	Litro
2065	24900029	Pigmentos organicos	Litro
2066	24900030	Pinturas a base de latex	Litro
2067	24900031	Pinturas acrilicas	Litro
2068	24900032	Pinturas anticorrosivas	Litro
2069	24900033	Pinturas antiderrapantes	Litro
2070	24900034	Pinturas de aceite	Litro
2071	24900035	Pinturas de aluminio	Litro
2072	24900036	Pinturas fluorescentes	Litro
2073	24900037	Pinturas impermeabilizantes	Litro
2074	24900038	Pinturas marinas	Litro
2075	24900039	Pinturas para albercas	Litro
2076	24900040	Pinturas para carteles y cuadros	Litro
2077	24900041	Pinturas para pizarrones	Litro
2078	24900042	Pinturas para recubrimientos primarios	Litro
2079	24900043	Pinturas para transito (reflejantes)	Litro
2080	24900044	Pinturas vinilicas	Litro
2081	24900045	Solventes adelgazadores	Litro
2082	24900046	Solventes para pintura	Litro
2083	24900047	Tes para tuberia	Pieza
2084	24900048	Pelicula o lamina de control solar (filtro solar)	Metro Cuadrado
2085	24900049	Cubierta laminada plastica	Metro Cuadrado
2086	24900050	Resanador de madera	Litro
2087	24900051	Sellador	Litro
2088	24900052	Silicon	Pieza
2089	24900053	Cera automotiva	Pieza
2090	24900054	Compuestos pulidores	Pieza
2091	24900055	Removedor	Pieza
2092	24900056	Masilla	Pieza
2093	2500	Productos quimicos, farmaceuticos y de laboratorio	
2094	2510	Productos quimicos basicos	
2095	25101	Productos quimicos basicos	
2096	25100001	Acidos aromaticos (compuestos aromaticos)	Litro
2097	25100002	Acidos sulfunicos (compuestos aromaticos)	Litro
2098	25100003	Alcoholes (compuestos alifaticos)	Litro
2099	25100004	Alcoholes aromaticos y fenoles (compuestos aromaticos)	Litro
2100	25100005	Aldehidos y cetonas (compuestos alifaticos)	Litro
2101	25100006	Aldehidos, cetonas y quinonas (compuestos aromaticos)	Litro
2102	25100007	Antigenos (excluye oxigeno via) (inorganica basica)	Pieza
2103	25100008	Boro (IIIA) (inorganica basica)	Pieza
2104	25100009	Compuestos nitro-aromaticos (compuestos aromaticos)	Pieza
2105	25100010	Fluoruro de sodio	Pieza
2106	25100011	Funcion acido (compuestos alifaticos)	Pieza
2107	25100012	Funcion amida (compuestos alifaticos)	Pieza
2108	25100013	Funcion amina (compuestos alifaticos)	Pieza
2109	25100014	Funcion anhidrido de acido (compuestos alifaticos)	Pieza
2110	25100015	Funcion ester (compuestos alifaticos)	Pieza
2111	25100016	Funcion eter-oxido (compuestos alifaticos)	Pieza
2112	25100017	Funciones nitrito e isonitrito (compuestos alifaticos)	Pieza
2113	25100018	Funciones nitrogenadas y oxinitradas (compuestos alifaticos)	Pieza
2114	25100019	Funciones oxigenadas derivadas (compuestos alifaticos)	Pieza
2115	25100020	Funciones oxigenadas y oxihidrogenadas (compuestos alifaticos)	Pieza
2116	25100021	Glucidos, lipidos, aminoacidos-proteinas (compuestos aromaticos)	Pieza
2117	25100022	Grupo de carbono (iva) (inorganica basica)	Pieza
2118	25100023	Grupo de nitrogeno (va) (inorganica basica)	Pieza
2119	25100024	Halogenados (compuestos aromaticos)	Pieza
2120	25100025	Halogenos compuestos de los (viia) (inorganica basica)	Pieza
2121	25100026	Haluros de acidos (compuestos alifaticos)	Pieza
2122	25100027	Hidrocarburos aciclicos no saturados (alquenos y alquinos) (compuestos alifaticos)	Pieza
2123	25100028	Hidrocarburos aciclicos saturados (alcanos) (compuestos alifaticos)	Pieza
2124	25100029	Hidrocarburos halogenados (compuestos alifaticos)	Pieza
2125	25100030	Hidrogeno (inorganica basica)	Pieza
2126	25100031	Homologos del benceno (compuestos aromaticos)	Pieza
2127	25100032	Metales ligeros (ia. Iia.) (inorganica basica)	Pieza
2128	25100033	Metales pesados (iiib.ivb.vb.vib.viib.fragiles. Viiib. Ductiles) (inorganica basica)	Pieza
2129	25100034	Nitrato de amonio	Pieza
2130	25100035	Oxigeno (inorganica basica)	Pieza
2131	25100036	Polioles (compuestos alifaticos)	Pieza
2132	25100037	Reactivos analiticos	Litro
2133	25100038	Resinas quimicas	Litro
2134	25100039	Substancias quimicas para tratamientos de  agua	Litro
2135	25100040	Sulfato de amonio	Kilogramo
2136	25100041	Hule sintetico y elastomeros	Pieza
2137	25100042	Pasta al sulfato	Pieza
2138	25100043	Pasta de bagazo viscosa	Pieza
2139	25100044	Pasta mecanica	Pieza
2140	25100046	Pulimentos y lustradores	Kilogramo
2141	25100047	Sulfato de aluminio	Kilogramo
2142	25100048	Abrasivos	Litro
2143	25100049	Compuesto quimico	Litro
2144	25100050	Desemulsionante	Litro
2145	25100051	Ether	Litro
2146	25100052	Glicerina	Litro
2147	25100053	Poliuretano	Kilogramo
2148	25100054	Rodamina	Kilogramo
2149	25100055	Safranina	Kilogramo
2150	25100056	Sulfato de Sodio	Kilogramo
2151	25100057	Sulfato de Zinc	Kilogramo
2152	25100058	Sulfito de Bismuto	Kilogramo
2153	25100059	Sulfuro de Sodio	Kilogramo
2154	25100060	Tiosulfato de sodio	Kilogramo
2155	25100061	Cloruro de potasio	Litro
2156	25100062	Agua desionizada	Litro
2157	25100063	Agua bidestilada	Litro
2158	2520	Fertilizantes, pesticidas y otros agroquimicos	
2159	25201	Plaguicidas, abonos y fertilizantes	
2160	25200001	Acido sulfurico (substancias y productos fertilizantes)	Litro
2161	25200002	Amoniaco anhidro (substancias y productos fertilizantes)	Litro
2162	25200003	Amoniaco aplicacion directa (substancias y productos fertilizantes)	Litro
2163	25200004	Fertilizantes compuestos (nitrogeno, fosforo y potasio) (substancias y productos fertilizantes)	Kilogramo
2164	25200005	Gas de coqueria (fertilizante) (substancias y productos fertilizantes)	Litro
2165	25200006	Gas natural (fertilizante) (substancias y productos fertilizantes)	Litro
2166	25200007	Nitrato de amonio grado fertilizantes (substancias y productos fertilizantes)	Kilogramo
2167	25200008	Plaguicidas (insecticidas)	Litro
2168	25200009	Roca fosforica (substancias y productos fertilizantes)	Kilogramo
2169	25200010	Sulfato de amonio. Grado fertilizantes (substancias y productos fertilizantes)	Kilogramo
2170	25200011	Superfosfato (substancias y productos fertilizantes)	Kilogramo
2171	25200012	Urea grado fertilizantes (substancias y productos fertilizantes)	Kilogramo
2172	25200013	Azametifos	Kilogramo
2173	25200014	Tierra negra	Kilogramo
2174	25200015	Borax	Kilogramo
2175	25200016	Hidroxido de potasio	Kilogramo
2176	25200017	Micro organismos Eficientes EM	Kilogramo
2177	25200018	Lombriz roja californiana	Kilogramo
2178	25200020	Acidos fulvicos	Kilogramo
2179	25200021	Acidos humicos	Kilogramo
2180	25200022	Complejos auxinicos	Kilogramo
2181	25200023	Fitohormonas	Kilogramo
2182	25200024	Pastilla de nutrientes	Kilogramo
2183	2530	Medicinas y productos farmaceuticos	
2184	25301	Medicinas y productos farmaceuticos	
2185	25300002	010.000.4368.00 Abacavir - lamivudina - zidovudina	Pieza
2186	25300003	010.000.4272.00 Abacavir	Pieza
2187	25300004	010.000.4273.00 Abacavir	Pieza
2188	25300006	010.000.4371.00 Abacavir-lamivudina	Pieza
2189	25300009	010.000.4247.00 Abciximab	Pieza
2190	25300012	010.000.5166.00 Acarbosa	Pieza
2191	25300014	010.000.0910.00 Aceite de almendras dulces	Pieza
2192	25300015	010.000.2118.00 Aceite de almendras dulces	Pieza
2193	25300017	010.000.1273.00 Aceite de ricino	Pieza
2194	25300019	010.000.0154.00 Aceite mineral	Pieza
2195	25300028	010.000.2303.00 Acetazolamida	Pieza
2196	62401009	Demolicion de escuela	Obra
2197	25300029	010.000.2302.00 Acetazolamida	Pieza
2198	25300032	010.000.4326.00 Acetilcisteina	Pieza
2199	25300033	010.000.2900.00 Acetilcolina cloruro de	Pieza
2200	25300036	010.000.4263.00 Aciclovir	Pieza
2201	25300037	010.000.2126.00 Aciclovir	Pieza
2202	25300038	010.000.4264.00 Aciclovir	Pieza
2203	25300039	010.000.2830.00 Aciclovir	Pieza
2204	25300041	010.000.0101.00 Acido acetilsalicilico	Pieza
2205	25300042	010.000.0103.00 Acido acetilsalicilico	Pieza
2206	25300044	010.000.4161.00 Acido alendronico	Pieza
2207	25300045	010.000.4164.00 Acido alendronico	Pieza
2208	25300047	010.000.4237.00 Acido aminocaproico	Pieza
2209	25300049	010.000.5229.00 Acido Ascorbico	Pieza
2210	25300050	010.000.2707.00 Acido ascorbico	Pieza
2211	25300052	010.000.1711.00 Acido folico	Pieza
2212	25300053	010.000.1700.00 Acido folico	Pieza
2213	25300056	010.000.2152.00 Acido folinico	Pieza
2214	25300057	010.000.1707.00 Acido folinico	Pieza
2215	25300058	010.000.2192.00 Acido folinico	Pieza
2216	25300059	010.000.5233.00 Acido folinico	Pieza
2217	25300062	010.000.5306.00 Acido micofenolico	Pieza
2218	25300063	010.000.5301.00 Acido micofenolico	Pieza
2219	25300064	010.000.5303.00 Acido micofenolico	Pieza
2220	25300066	010.000.2322.00 Acido nalidixico	Pieza
2221	25300068	010.000.0656.00 Acido nicotinico	Pieza
2222	25300070	010.000.0904.00 Acido retinoico	Pieza
2223	25300072	010.000.4167.00 Acido risedronico	Pieza
2224	25300073	010.000.4166.00 Acido risedronico	Pieza
2225	25300075	010.000.4185.00 Acido ursodeoxicolico	Pieza
2226	25300077	010.000.2620.00 Acido valproico	Pieza
2227	25300079	010.000.5468.00 Acido zoledronico	Pieza
2228	25300083	010.000.4375.00 Adefovir	Pieza
2229	25300085	010.000.5099.00 Adenosina	Pieza
2230	25300088	010.000.5546.00 Agalsidasa beta	Pieza
2231	25300090	010.000.3674.00 Agua inyectable	Pieza
2232	25300091	010.000.3673.00 Agua inyectable	Pieza
2233	25300092	010.000.3675.00 Agua inyectable	Pieza
2234	25300096	010.000.0831.00 Alantoina y alquitran de hulla	Pieza
2235	25300100	010.000.1345.00 Albendazol	Pieza
2236	25300101	010.000.1347.00 Albendazol	Pieza
2237	25300102	010.000.1344.00 Albendazol	Pieza
2238	25300103	010.000.2172.00 Alcohol polivinilico	Pieza
2239	25300107	010.000.5304.00 Alfa cetoanalogos de aminoacidos	Pieza
2240	25300108	010.000.5330.00 Alfa dornasa	Pieza
2241	25300111	010.000.5548.00 Alglucosidasa alfa	Pieza
2242	25300113	010.000.0871.00 Alibour	Pieza
2243	25300115	010.000.5411.00 Alimento medico para menores de un año con acidemia isovalerica y otros trastornos del metabolismo de la leucina	Pieza
2244	25300116	010.000.5412.00 Alimento medico para niños de 1 a 8 años con acidemia isovalerica y otros trastornos del metabolismo de la leucina	Pieza
2245	25300118	010.000.5413.00 Alimento medico para niños de 8 años a adultos con acidemia isovalerica y otros trastornos del metabolismo de la leucina	Pieza
2246	25300122	010.000.5406.00 Alimento medico para pacientes con acidemia metilmalonica y propionica, de 8 años o mayores y adultos	Pieza
2247	25300123	010.000.5405.00 Alimento medico para pacientes con acidemia metilmalonica y propionica, de recien nacidos a 7 años 11 meses de edad	Pieza
2248	25300127	010.000.5407.00 Alimento medico para pacientes con enfermedad de orina de jarabe de maple (arce), de recien nacidos a 7 años 11 meses de edad	Pieza
2249	25300129	010.000.5410.00 Alimento medico para pacientes con homocistinuria, de 8 años o mayores y adultos	Pieza
2250	25300131	010.000.5409.00 Alimento medico para pacientes con homocistinuria, recien nacidos a 7 años 11 meses de edad	Pieza
2251	25300133	010.000.5404.00 Alimento medico para pacientes con trastorno del ciclo de la urea, de 8 años o mayores y adultos	Pieza
2252	25300134	010.000.5403.00 Alimento medico para pacientes con trastorno del ciclo de la urea, recien nacido a 7 años 11 meses de edad	Pieza
2253	25300141	010.000.3451.00 Alopurinol	Pieza
2254	25300143	040.000.2500.00 Alprazolam	Pieza
2255	25300144	040.000.2499.00 Alprazolam	Pieza
2256	25300146	010.000.5107.00 Alteplasa	Pieza
2257	25300150	010.000.1222.00 Aluminio	Pieza
2258	25300151	010.000.1221.00 Aluminio	Pieza
2259	25300154	010.000.2462.00 Ambroxol	Pieza
2260	25300155	010.000.2463.00 Ambroxol	Pieza
2261	25300159	010.000.5439.00 Amifostina	Pieza
2262	25300164	010.000.2737.00 Aminoacidos con electrolitos	Pieza
2263	25300169	010.000.5393.00 Aminoacidos enriquecidos con aminoacidos de cadena ramificada	Pieza
2264	25300171	010.000.2168.00 Aminoacidos esenciales sin electrolitos	Pieza
2265	25300173	010.000.0426.00 Aminofilina	Pieza
2266	25300175	010.000.4107.00 Amiodarona	Pieza
2267	25300176	010.000.4110.00 Amiodarona	Pieza
2268	25300178	040.000.3305.00 Amitriptilina	Pieza
2269	25300183	010.000.2130.00 Amoxicilina - acido clavulanico	Pieza
2270	25300184	010.000.2129.00 Amoxicilina - acido clavulanico	Pieza
2271	25300189	010.000.1931.00 Ampicilina	Pieza
2272	25300190	010.000.1930.00 Ampicilina	Pieza
2273	25300191	010.000.1929.00 Ampicilina	Pieza
2274	25300194	010.000.4275.00 Amprenavir	Pieza
2275	25300201	010.000.5449.00 Anastrozol	Pieza
2276	25300227	010.000.5239.00 Anticuerpos monoclonales CD3	Pieza
2277	25300262	020.000.3841.00 Antitoxina difterica equina	Pieza
2278	25300264	020.000.3845.00 Antitoxina tetanica equina	Pieza
2279	25300266	010.000.5341.00 Antitrombina III	Pieza
2280	25300267	010.000.5340.00 Antitrombina III	Pieza
2281	25300274	010.000.5130.00 Antralina	Pieza
2282	25300276	010.000.4442.00 Aprepitant	Pieza
2283	25300278	010.000.5246.00 Aprotinina	Pieza
2284	25300280	010.000.4490.00 Aripiprazol	Pieza
2285	25300281	010.000.4491.00 Aripiprazol	Pieza
2286	25300282	010.000.4492.00 Aripiprazol	Pieza
2287	25300284	010.000.4267.00 Atazanavir	Pieza
2288	25300285	010.000.4266.00 Atazanavir	Pieza
2289	25300287	010.000.3307.00 Atomoxetina	Pieza
2290	25300288	010.000.3308.00 Atomoxetina	Pieza
2291	25300289	010.000.3309.00 Atomoxetina	Pieza
2292	25300291	010.000.5106.00 Atorvastatina	Pieza
2293	25300293	010.000.1546.00 Atosiban	Pieza
2294	25300294	010.000.1545.00 Atosiban	Pieza
2295	25300296	010.000.0204.00 Atropina	Pieza
2296	25300298	010.000.2872.00 Atropina	Pieza
2297	25300299	010.000.2873.00 Atropina	Pieza
2298	25300301	010.000.4503.00 Aurotiomalato sodico	Pieza
2299	25300304	010.000.3461.00 Azatioprina	Pieza
2300	25300312	010.000.3050.00 BCG Inmunoterapeutico	Pieza
2301	25300313	010.000.0477.00 Beclometasona dipropionato de	Pieza
2302	25300317	010.000.0861.00 Bencilo	Pieza
2303	25300319	010.000.1938.00 Bencilpenicilina benzatinica compuesta	Pieza
2304	25300321	010.000.1923.00 Bencilpenicilina procainica - bencilpenicilina cristalina	Pieza
2305	25300322	010.000.1924.00 Bencilpenicilina procainica - bencilpenicilina cristalina	Pieza
2306	25300324	010.000.2510.00 Bencilpenicilina procainica	Pieza
2307	25300326	010.000.1921.00 Bencilpenicilina sodica cristalina	Pieza
2308	25300327	010.000.1933.00 Bencilpenicilina sodica cristalina	Pieza
2309	25300330	010.000.1925.00 Benzatina bencilpenicilina	Pieza
2310	25300331	010.000.2509.00 Benzatina bencilpenicilina	Pieza
2311	25300332	010.000.0071.00 Benzatina bencilpenicilina	Pieza
2312	25300336	010.000.2433.00 Benzonatato	Pieza
2313	25300337	010.000.2435.00 Benzonatato	Pieza
2314	25300343	010.000.2153.00 Betametasona acetato de y fosfato disodico de	Pieza
2315	25300345	010.000.2141.00 Betametasona	Pieza
2316	25300346	010.000.2119.00 Betametasona	Pieza
2317	25300348	010.000.2173.00 Betaxolol	Pieza
2318	25300350	010.000.5472.00 Bevacizumab	Pieza
2319	25300351	010.000.5473.00 Bevacizumab	Pieza
2320	25300353	010.000.0655.00 Bezafibrato	Pieza
2321	25300357	010.000.3619.00 Bicarbonato de sodio	Pieza
2322	25300358	010.000.3618.00 Bicarbonato de sodio	Pieza
2323	25300360	040.000.2653.00 Biperideno	Pieza
2324	25300361	040.000.2652.00 Biperideno	Pieza
2325	25300363	010.000.1263.00 Bismuto	Pieza
2326	25300365	010.000.1767.00 Bleomicina	Pieza
2327	25300367	010.000.4448.00 Bortezomib	Pieza
2328	25300370	010.000.4420.00 Brimonidina - timolol	Pieza
2329	25300371	010.000.4413.00 Brimonidina	Pieza
2330	25300373	040.000.4482.00 Bromazepam	Pieza
2331	25300375	010.000.2159.00 Bromhexina	Pieza
2332	25300376	010.000.2158.00 Bromhexina	Pieza
2333	25300378	010.000.1096.00 Bromocriptina	Pieza
2334	25300382	010.000.0446.00 Budesonida - formoterol	Pieza
2335	25300383	010.000.0445.00 Budesonida - formoterol	Pieza
2336	25300384	010.000.4336.00 Budesonida	Pieza
2337	25300385	010.000.4334.00 Budesonida	Pieza
2338	25300392	010.000.0271.00 Bupivacaina	Pieza
2339	25300394	040.000.2098.00 Buprenorfina	Pieza
2340	25300395	040.000.2097.00 Buprenorfina	Pieza
2341	25300396	040.000.4026.00 Buprenorfina	Pieza
2342	25300399	010.000.5462.00 Buserelina	Pieza
2343	25300401	010.000.1755.00 Busulfan	Pieza
2344	25300403	010.000.0113.00 Butilhioscina  metamizol	Pieza
2345	25300404	010.000.2146.00 Butilhioscina  metamizol	Pieza
2346	25300411	010.000.1006.00 Calcio	Pieza
2347	25300415	010.000.1095.00 Calcitriol	Pieza
2348	25300416	010.000.2530.00 Candesartan Cilexetilo - Hidroclorotiazida	Pieza
2349	25300419	010.000.5460.00 Capecitabina	Pieza
2350	25300420	010.000.5461.00 Capecitabina	Pieza
2351	25300421	010.000.4031.00 Capsaicina	Pieza
2352	25300423	010.000.0574.00 Captopril	Pieza
2353	25300425	040.000.2609.00 Carbamazepina	Pieza
2354	25300426	040.000.2608.00 Carbamazepina	Pieza
2355	25300427	040.000.2164.00 Carbamazepina	Pieza
2356	25300431	010.000.2242.00 Carbon activado	Pieza
2357	25300433	010.000.4431.00 Carboplatino	Pieza
2358	25300435	010.000.1758.00 Carmustina	Pieza
2359	25300437	010.000.2545.00 Carvedilol	Pieza
2360	25300439	010.000.0022.00 Caseinato de calcio	Pieza
2361	25300441	010.000.5313.00 Caspofungina	Pieza
2362	25300442	010.000.5314.00 Caspofungina	Pieza
2363	25300444	010.000.2131.00 Cefaclor	Pieza
2364	25300445	010.000.2163.00 Cefaclor	Pieza
2365	25300447	010.000.1939.00 Cefalexina	Pieza
2366	25300449	010.000.5256.00 Cefalotina	Pieza
2367	25300452	010.000.5284.00 Cefepima	Pieza
2368	25300454	010.000.1935.00 Cefotaxima	Pieza
2369	25300456	010.000.5310.00 Cefpiroma	Pieza
2370	25300457	010.000.5311.00 Cefpiroma	Pieza
2371	25300459	010.000.4254.00 Ceftazidima	Pieza
2372	25300461	010.000.1937.00 Ceftriaxona	Pieza
2373	25300465	010.000.5505.00 Celecoxib	Pieza
2374	25300466	010.000.5506.00 Celecoxib	Pieza
2375	25300468	010.000.4210.00 Cetroelix	Pieza
2376	25300469	010.000.4211.00 Cetroelix	Pieza
2377	25300474	010.000.1752.00 Ciclofosfamida	Pieza
2378	25300475	010.000.1753.00 Ciclofosfamida	Pieza
2379	25300477	040.000.2877.00 Ciclopentolato	Pieza
2380	25300479	010.000.4298.00 Ciclosporina	Pieza
2381	25300480	010.000.4306.00 Ciclosporina	Pieza
2382	25300481	010.000.4294.00 Ciclosporina	Pieza
2383	25300482	010.000.4236.00 Ciclosporina	Pieza
2384	25300483	010.000.4416.00 Ciclosporina	Pieza
2385	25300486	010.000.5451.00 Cinarizina	Pieza
2386	25300488	010.000.2247.00 Cinitaprida	Pieza
2387	25300489	010.000.2248.00 Cinitaprida	Pieza
2388	25300490	010.000.2249.00 Cinitaprida	Pieza
2389	25300492	010.000.4265.00 Ciprofibrato	Pieza
2390	25300494	010.000.4255.00 Ciprofloxacino	Pieza
2391	25300496	010.000.2174.00 Ciprofloxacino	Pieza
2392	25300497	010.000.4258.00 Ciprofloxacino	Pieza
2393	25300499	010.000.5420.00 Ciproterona	Pieza
2394	25300501	010.000.1511.00 Ciproterona-Etinilestradiol	Pieza
2395	25300503	010.000.1208.00 Cisaprida	Pieza
2396	25300504	010.000.2147.00 Cisaprida	Pieza
2397	25300505	010.000.1209.00 Cisaprida	Pieza
2398	25300507	010.000.4061.00 Cisatracurio, besilato de	Pieza
2399	25300509	010.000.3046.00 Cisplatino	Pieza
2400	25300513	010.000.1775.00 Citarabina	Pieza
2401	25300515	010.000.2132.00 Claritromicina	Pieza
2402	25300517	010.000.2133.00 Clindamicina	Pieza
2403	25300518	010.000.4136.00 Clindamicina	Pieza
2404	25300519	010.000.1973.00 Clindamicina	Pieza
2405	25300520	010.000.1976.00 Clindamicina	Pieza
2406	25300522	010.000.0872.00 Clioquinol	Pieza
2407	25300524	040.000.2165.00 Clobazam	Pieza
2408	25300526	010.000.5469.00 Clodronato disodico	Pieza
2409	25300528	010.000.1531.00 Clomifeno	Pieza
2410	25300530	040.000.2613.00 Clonazepam	Pieza
2411	25300531	040.000.2614.00 Clonazepam	Pieza
2412	25300532	040.000.2612.00 Clonazepam	Pieza
2413	25300534	010.000.2101.00 Clonidina	Pieza
2414	25300536	010.000.4028.00 Clonixinato de lisina	Pieza
2415	25300540	010.000.5352.00 Cloral	Pieza
2416	25300542	010.000.1754.00 Clorambucilo	Pieza
2417	25300544	010.000.1991.00 Cloranfenicol	Pieza
2418	25300545	010.000.1992.00 Cloranfenicol	Pieza
2419	25300546	010.000.2821.00 Cloranfenicol	Pieza
2420	25300548	010.000.2822.00 Cloranfenicol	Pieza
2421	25300549	010.000.2175.00 Cloranfenicol y sulfacetamida sodica	Pieza
2422	25300553	010.000.2471.00 Clorfenamina compuesta	Pieza
2423	25300554	010.000.0408.00 Clorfenamina	Pieza
2424	25300555	010.000.2142.00 Clorfenamina	Pieza
2425	25300556	010.000.0402.00 Clorfenamina	Pieza
2426	25300558	010.000.1521.00 Clormadinona	Pieza
2427	25300560	040.000.3213.00 Clorodiazepoxido	Pieza
2428	25300562	010.000.5079.00 Cloropiramina	Pieza
2429	25300564	010.000.2030.00 Cloroquina	Pieza
2430	25300566	010.000.0561.00 Clortalidona	Pieza
2431	25300569	010.000.0524.00 Cloruro de potasio	Pieza
2432	25300571	010.000.3634.00 Cloruro de sodio	Pieza
2433	25300572	010.000.3633.00 Cloruro de sodio	Pieza
2434	25300573	010.000.2899.00 Cloruro de sodio	Pieza
2435	25300575	010.000.3627.00 Cloruro de sodio	Pieza
2436	25300576	010.000.3610.00 Cloruro de sodio	Pieza
2437	25300580	010.000.5386.00 Cloruro de sodio	Pieza
2438	25300582	010.000.3612.00 Cloruro de sodio y glucosa	Pieza
2439	25300584	010.000.3613.00 Cloruro de sodio y glucosa	Pieza
2440	25300588	040.000.2160.00 Codeina con efedrina	Pieza
2441	25300593	010.000.3409.00 Colchicina	Pieza
2442	25300598	010.000.2714.00 Complejo B	Pieza
2443	25300600	010.000.4219.00 Complejo coagulante anti-Inhibidor del factor VIII	Pieza
2444	25300601	010.000.4218.00 Complejo coagulante anti-Inhibidor del factor VIII	Pieza
2445	25300613	010.000.4151.00 Coriogonadotropina alfa	Pieza
2446	25300616	010.000.4159.00 Corticotropina	Pieza
2447	25300617	010.000.4147.00 Corticotropina	Pieza
2448	25300621	010.000.2806.00 Cromoglicato de sodio	Pieza
2449	25300622	010.000.0464.00 Cromoglicato de sodio	Pieza
2450	25300624	010.000.5466.00 Cultivo BCG	Pieza
2451	25300626	010.000.3003.00 Dacarbazina	Pieza
2452	25300630	010.000.4429.00 Dactinomicina	Pieza
2453	25300632	010.000.1093.00 Danazol	Pieza
2454	25300634	010.000.0906.00 Dapsona	Pieza
2455	25300640	010.000.4228.00 Daunorubicina	Pieza
2456	25300642	010.000.2204.00 Deferasirox	Pieza
2457	25300643	010.000.2205.00 Deferasirox	Pieza
2458	25300644	010.000.2206.00 Deferasirox	Pieza
2459	25300646	010.000.4509.00 Deflazacort	Pieza
2460	25300647	010.000.4507.00 Deflazacort	Pieza
2461	25300648	010.000.4505.00 Deflazacort	Pieza
2462	25300651	010.000.0234.00 Desflurano	Pieza
2463	25300653	010.000.5169.00 Desmopresina	Pieza
2464	25300655	010.000.1097.00 Desmopresina	Pieza
2465	25300656	010.000.1099.00 Desmopresina	Pieza
2466	25300658	010.000.2212.00 Desogestrel	Pieza
2467	25300660	010.000.3505.00 Desogestrel y etinilestradiol	Pieza
2468	25300661	010.000.3508.00 Desogestrel y etinilestradiol	Pieza
2469	25300664	010.000.4241.00 Dexametasona	Pieza
2470	25300665	010.000.2176.00 Dexametasona	Pieza
2471	25300666	010.000.3432.00 Dexametasona	Pieza
2472	25300671	010.000.4444.00 Dexrazoxano	Pieza
2473	25300673	010.000.0641.00 Dextran	Pieza
2474	25300674	010.000.4551.00 Dextran	Pieza
2475	25300675	010.000.2161.00 Dextrometorfano	Pieza
2476	25300676	010.000.2431.00 Dextrometorfano	Pieza
2477	25300677	040.000.0107.00 Dextropropoxifeno	Pieza
2478	25300678	040.000.0202.00 Diazepam	Pieza
2479	25300681	040.000.3216.00 Diazepam	Pieza
2480	25300682	040.000.3215.00 Diazepam	Pieza
2481	25300685	010.000.0568.00 Diazoxido	Pieza
2482	25300689	010.000.3417.00 Diclofenaco	Pieza
2483	25300690	010.000.5501.00 Diclofenaco	Pieza
2484	25300693	010.000.1926.00 Dicloxacilina	Pieza
2485	25300694	010.000.1928.00 Dicloxacilina	Pieza
2486	25300695	010.000.1927.00 Dicloxacilina	Pieza
2487	25300698	010.000.5321.00 Didanosina	Pieza
2488	25300699	010.000.5322.00 Didanosina	Pieza
2489	25300700	010.000.5323.00 Didanosina	Pieza
2490	25300702	010.000.5270.00 Didanosina	Pieza
2491	25300707	010.000.2739.00 Dieta polimerica a base de caseinato de calcio o proteinas, grasas, vitaminas, minerales	Pieza
2492	25300709	010.000.5392.00 Dieta polimerica con fibra	Pieza
2493	25300713	010.000.0405.00 Difenhidramina	Pieza
2494	25300714	010.000.0406.00 Difenhidramina	Pieza
2495	25300716	010.000.3112.00 Difenidol	Pieza
2496	25300717	010.000.3111.00 Difenidol	Pieza
2497	25300720	010.000.0503.00 Digoxina	Pieza
2498	25300721	010.000.0504.00 Digoxina	Pieza
2499	25300722	010.000.0502.00 Digoxina	Pieza
2500	25300724	010.000.2671.00 Dihidroergotamina/Paracetamol/ Cafeina	Pieza
2501	25300728	010.000.2112.00 Diltiazem	Pieza
2502	25300730	010.000.2196.00 Dimenhidrinato	Pieza
2503	25300731	010.000.3113.00 Dimenhidrinato	Pieza
2504	25300733	010.000.4203.00 Dinoprostona	Pieza
2505	25300738	010.000.3400.00 Dipiridamol-acido acetilsalicilico	Pieza
2506	25300740	010.000.2177.00 Dipivefrina	Pieza
2507	25300743	010.000.1302.00 Diyodohidroxiquinoleina	Pieza
2508	25300744	010.000.1301.00 Diyodohidroxiquinoleina	Pieza
2509	25300746	010.000.0615.00 Dobutamina	Pieza
2510	25300748	010.000.5457.00 Docetaxel	Pieza
2511	25300749	010.000.5437.00 Docetaxel	Pieza
2512	25300754	010.000.0614.00 Dopamina	Pieza
2513	25300756	010.000.4410.00 Dorzolamida	Pieza
2514	25300758	010.000.4412.00 Dorzolamida y timolol	Pieza
2515	25300760	010.000.1940.00 Doxiciclina	Pieza
2516	25300761	010.000.1941.00 Doxiciclina	Pieza
2517	25300763	010.000.1764.00 Doxorubicina	Pieza
2518	25300764	010.000.1766.00 Doxorubicina	Pieza
2519	25300765	010.000.1765.00 Doxorubicina	Pieza
2520	25300776	010.000.5298.00 Efavirenz	Pieza
2521	25300777	010.000.4370.00 Efavirenz	Pieza
2522	25300779	040.000.2107.00 Efedrina	Pieza
2523	25300783	010.000.3622.00 Electrolitos orales	Pieza
2524	25300785	010.000.4366.00 Eletriptan	Pieza
2525	25300786	010.000.4367.00 Eletriptan	Pieza
2526	25300788	010.000.4276.00 Emtricitabina	Pieza
2527	25300790	010.000.4396.00 Emtricitabina-Tenofovir disoproxil fumarato	Pieza
2528	25300792	010.000.2501.00 Enalapril o lisinopril o ramipril	Pieza
2529	25300794	010.000.4269.00 Enfuvirtida	Pieza
2530	25300796	010.000.4242.00 Enoxaparina	Pieza
2531	25300797	010.000.2154.00 Enoxaparina	Pieza
2532	25300798	010.000.4224.00 Enoxaparina	Pieza
2533	25300800	010.000.2655.00 Entacapona, levodopa, carbidopa	Pieza
2534	25300802	010.000.4385.00 Entecavir	Pieza
2535	25300803	010.000.4386.00 Entecavir	Pieza
2536	25300807	010.000.3143.00 Epinastina	Pieza
2537	25300809	010.000.0611.00 Epinefrina	Pieza
2538	25300818	040.000.1544.00 Ergometrina (ergonovina)	Pieza
2539	25300820	040.000.2673.00 Ergotamina y cafeina	Pieza
2540	25300822	010.000.1971.00 Eritromicina	Pieza
2541	25300823	010.000.2134.00 Eritromicina	Pieza
2542	25300824	010.000.1972.00 Eritromicina	Pieza
2543	25300826	010.000.5332.00 Eritropoyetina	Pieza
2544	25300828	010.000.5339.00 Eritropoyetina	Pieza
2545	25300832	010.000.5285.00 Ertapenem	Pieza
2546	25300833	010.000.4301.00 Ertapenem	Pieza
2547	25300837	010.000.5104.00 Esmolol	Pieza
2548	25300838	010.000.5105.00 Esmolol	Pieza
2549	25300840	010.000.5188.00 Esomeprazol	Pieza
2550	25300842	010.000.2156.00 Espironolactona	Pieza
2551	25300843	010.000.2304.00 Espironolactona	Pieza
2552	25300845	010.000.5293.00 Estavudina	Pieza
2553	25300846	010.000.5294.00 Estavudina	Pieza
2554	25300858	010.000.1497.00 Estradiol ciproterona	Pieza
2555	25300859	010.000.1496.00 Estradiol noretisterona	Pieza
2556	25300860	010.000.1513.00 Estradiol trimegestona	Pieza
2557	25300861	010.000.1514.00 Estradiol trimegestona	Pieza
2558	25300863	010.000.1494.00 Estradiol valerato de	Pieza
2559	25300864	010.000.1495.00 Estradiol valerato de	Pieza
2560	25300865	010.000.1504.00 Estradiol valerato de	Pieza
2561	25300867	010.000.1516.00 Estradiol, drospirenona	Pieza
2562	25300871	010.000.5443.00 Estramustina	Pieza
2563	25300873	010.000.2403.00 Estreptomicina	Pieza
2564	25300875	010.000.1736.00 Estreptoquinasa	Pieza
2565	25300876	010.000.1734.00 Estreptoquinasa	Pieza
2566	25300877	010.000.1735.00 Estreptoquinasa	Pieza
2567	25300879	010.000.4206.00 Estriol	Pieza
2568	25300881	010.000.1506.00 Estrogenos conjugados	Pieza
2569	25300882	010.000.1502.00 Estrogenos conjugados	Pieza
2570	25300883	010.000.1489.00 Estrogenos conjugados	Pieza
2571	25300885	010.000.1499.00 Estrogenos conjugados	Pieza
2572	25300887	010.000.1508.00 Estrogenos conjugados y medroxiprogesterona	Pieza
2573	25300888	010.000.1509.00 Estrogenos conjugados y medroxiprogesterona	Pieza
2574	25300891	010.000.2405.00 Etambutol	Pieza
2575	25300896	010.000.4036.00 Etofenamato	Pieza
2576	25300898	040.000.0243.00 Etomidato	Pieza
2577	25300900	010.000.3510.00 Etonogestrel	Pieza
2578	25300902	010.000.4230.00 Etoposido	Pieza
2579	25300912	020.000.3847.00 Faboterapico polivalente antialacran	Pieza
2580	25300913	020.000.3848.00 Faboterapico polivalente antiaracnido	Pieza
2581	25300914	020.000.3850.00 Faboterapico polivalente anticoralillo	Pieza
2582	25300915	020.000.3849.00 Faboterapico polivalente antiviperino	Pieza
2583	25300917	010.000.4239.00 Factor antihemofilico humano	Pieza
2584	25300919	010.000.5344.00 Factor IX	Pieza
2585	25300920	010.000.5238.00 Factor IX	Pieza
2586	25300921	010.000.5343.00 Factor IX	Pieza
2587	25300923	010.000.5252.00 Factor VIII recombinante	Pieza
2588	25300924	010.000.5253.00 Factor VIII recombinante	Pieza
2589	25300926	010.000.2114.00 Felodipino	Pieza
2590	25300928	010.000.2331.00 Fenazopiridina	Pieza
2591	25300930	010.000.3102.00 Fenilefrina	Pieza
2592	25300931	010.000.2871.00 Fenilefrina	Pieza
2593	25300934	010.000.2178.00 Feniramina/nafazolina	Pieza
2594	25300937	010.000.2624.00 Fenitoina	Pieza
2595	25300938	010.000.2611.00 Fenitoina	Pieza
2596	25300939	010.000.2610.00 Fenitoina	Pieza
2597	25300940	010.000.0525.00 Fenitoina	Pieza
2598	25300942	040.000.2619.00 Fenobarbital	Pieza
2599	25300943	040.000.2601.00 Fenobarbital	Pieza
2600	25300944	040.000.2602.00 Fenobarbital	Pieza
2601	25300946	040.000.4027.00 Fentanilo	Pieza
2602	25300947	040.000.0242.00 Fentanilo	Pieza
2603	25300949	010.000.3145.00 Fexofenadina	Pieza
2604	25300950	010.000.3146.00 Fexofenadina	Pieza
2605	25300952	010.000.5432.00 Filgrastim	Pieza
2606	25300954	010.000.4302.00 Finasterida	Pieza
2607	25300960	010.000.5267.00 Fluconazol	Pieza
2608	25300961	010.000.2135.00 Fluconazol	Pieza
2609	25300963	010.000.5455.00 Fludarabina	Pieza
2610	25300965	010.000.4160.00 Fludrocortisona	Pieza
2611	25300968	040.000.4054.00 Flumazenil	Pieza
2612	25300970	010.000.5353.00 Flunarizina	Pieza
2613	25300972	040.000.4478.00 Flunitrazepam	Pieza
2614	25300975	010.000.0811.00 Fluocinolona	Pieza
2615	25300976	010.000.2179.00 Fluorometalona	Pieza
2616	25300978	010.000.3012.00 Fluorouracilo	Pieza
2617	25300984	010.000.3261.00 Flupentixol	Pieza
2618	25300987	010.000.5426.00 Flutamida	Pieza
2619	25300989	010.000.0440.00 Fluticasona	Pieza
2620	25300990	010.000.0450.00 Fluticasona	Pieza
2621	25301003	010.000.4220.00 Fondaparinux	Pieza
2622	25301006	010.000.5400.00 Formula de inicio libre de fenilalanina	Pieza
2623	25301007	030.000.5398.00 Formula de proteina a base de aminoacidos	Pieza
2624	25301009	030.000.0021.00 Formula de proteina aislada de soya	Pieza
2625	25301015	030.000.0014.00 Formula de seguimiento o continuacion con o sin probioticos	Pieza
2626	25301017	010.000.5402.00 Formula libre de fenilalanina para adolescente y adulto	Pieza
2627	25301019	010.000.5397.00 Formula o Dieta Inmunorreguladora	Pieza
2628	25301021	010.000.4278.00 Fosamprenavir	Pieza
2629	25301023	010.000.3617.00 Fosfato de potasio	Pieza
2630	25301025	010.000.1277.00 Fosfato y citrato de sodio	Pieza
2631	25301030	010.000.1702.00 Fumarato ferroso	Pieza
2632	25301031	010.000.1701.00 Fumarato ferroso	Pieza
2633	25301033	010.000.2308.00 Furosemida	Pieza
2634	25301034	010.000.2157.00 Furosemida	Pieza
2635	25301035	010.000.2307.00 Furosemida	Pieza
2636	25301037	010.000.4359.00 Gabapentina	Pieza
2637	25301042	010.000.5268.00 Ganciclovir	Pieza
2638	25301045	010.000.5470.00 Gefitinib	Pieza
2639	25301048	010.000.5438.00 Gemcitabina	Pieza
2640	25301052	010.000.1955.00 Gentamicina	Pieza
2641	25301053	010.000.1954.00 Gentamicina	Pieza
2642	25301054	010.000.2828.00 Gentamicina	Pieza
2643	25301057	010.000.1042.00 Glibenclamida	Pieza
2644	25301059	010.000.1282.00 Glicerol	Pieza
2645	25301060	010.000.1278.00 Glicerol	Pieza
2646	25301062	010.000.2193.00 Glicofosfopeptical	Pieza
2647	25301066	010.000.4232.00 Globulina equina antitimocitica humana	Pieza
2648	25301068	010.000.2125.00 Glucagon	Pieza
2649	25301073	010.000.3605.00 Glucosa	Pieza
2650	25301074	010.000.3604.00 Glucosa	Pieza
2651	25301075	010.000.3603.00 Glucosa	Pieza
2652	25301076	010.000.3630.00 Glucosa	Pieza
2653	25301077	010.000.3625.00 Glucosa	Pieza
2654	25301078	010.000.3624.00 Glucosa	Pieza
2655	25301079	010.000.3632.00 Glucosa	Pieza
2656	25301080	010.000.3631.00 Glucosa	Pieza
2657	25301081	010.000.3607.00 Glucosa	Pieza
2658	25301082	010.000.3606.00 Glucosa	Pieza
2659	25301088	010.000.3049.00 Goserelina	Pieza
2660	25301089	010.000.3048.00 Goserelina	Pieza
2661	25301091	010.000.4439.00 Granisetron	Pieza
2662	25301092	010.000.4440.00 Granisetron	Pieza
2663	25301093	010.000.4441.00 Granisetron	Pieza
2664	25301094	010.000.4438.00 Granisetron	Pieza
2665	25301097	040.000.3253.00 Haloperidol	Pieza
2666	25301099	040.000.3251.00 Haloperidol	Pieza
2667	25301103	010.000.0621.00 Heparina	Pieza
2668	25301104	010.000.0622.00 Heparina	Pieza
2669	25301106	010.000.4402.00 Hialuronato de sodio	Pieza
2670	25301108	010.000.2116.00 Hidralazina	Pieza
2671	25301109	010.000.4201.00 Hidralazina	Pieza
2672	25301110	010.000.0570.00 Hidralazina	Pieza
2673	25301112	010.000.2301.00 Hidroclorotiazida	Pieza
2674	25301114	010.000.0813.00 Hidrocortisona	Pieza
2675	25301115	010.000.0474.00 Hidrocortisona	Pieza
2676	25301117	040.000.2113.00 Hidromorfona	Pieza
2677	25301121	010.000.4226.00 Hidroxicarbamida	Pieza
2678	25301124	010.000.1522.00 Hidroxiprogesterona caproato de	Pieza
2679	25301126	040.000.0409.00 Hidroxizina Gragea o	Pieza
2680	25301127	040.000.2143.00 Hidroxizina	Pieza
2681	25301130	010.000.1708.00 Hidroxocobalamina	Pieza
2682	25301133	010.000.1712.00 Hierro aminoquelado y acido folico	Pieza
2683	25301135	010.000.1705.00 Hierro dextran	Pieza
2684	25301137	010.000.2120.00 Higroplex Crema	Pieza
2685	25301143	010.000.2893.00 Hipromelosa	Pieza
2686	25301144	010.000.2814.00 Hipromelosa	Pieza
2687	25301146	010.000.2874.00 Homatropina	Pieza
2688	25301149	010.000.5442.00 Idarubicina	Pieza
2689	25301150	010.000.5441.00 Idarubicina	Pieza
2690	25301153	010.000.2827.00 Idoxuridina	Pieza
2691	25301157	010.000.4432.00 Ifosfamida	Pieza
2692	25301159	010.000.4227.00 Imatinib	Pieza
2693	25301160	010.000.4225.00 Imatinib	Pieza
2694	25301167	040.000.3302.00 Imipramina	Pieza
2695	25301169	010.000.4140.00 Imiquimod	Pieza
2696	25301171	010.000.5279.00 Indinavir	Pieza
2697	25301173	010.000.3413.00 Indometacina	Pieza
2698	25301174	010.000.4202.00 Indometacina	Pieza
2699	25301178	010.000.4508.00 Infliximab	Pieza
2700	25301180	010.000.1591.00 Inmunoglobulina anti D	Pieza
2701	25301184	010.000.4231.00 Inmunoglobulina antilinfocitos T humanos	Pieza
2702	25301189	020.000.3833.00 Inmunoglobulina humana antirrabica	Pieza
2703	25301191	020.000.3831.00 Inmunoglobulina humana hiperinmune antitetanica	Pieza
2704	25301193	020.000.3832.00 Inmunoglobulina humana normal	Pieza
2705	25301195	010.000.4156.00 Insulina aspartica	Pieza
2706	25301201	010.000.4168.00 Insulina glulisina	Pieza
2707	25301205	010.000.4157.00 Insulina humana de accion intermedia lenta	Pieza
2708	25301208	010.000.4148.00 Insulina lispro lispro protamina	Pieza
2709	25301209	010.000.4162.00 Insulina lispro	Pieza
2710	25301213	010.000.5251.00 Interferon (beta)	Pieza
2711	25301216	010.000.5245.00 Interferon alfa 2a	Pieza
2712	25301217	010.000.5245.01 Interferon alfa 2b	Pieza
2713	25301219	010.000.2188.00 Ipratropio - Salbutamol	Pieza
2714	25301220	010.000.2190.00 Ipratropio - Salbutamol	Pieza
2715	25301221	010.000.2187.00 Ipratropio	Pieza
2716	25301222	010.000.2162.00 Ipratropio	Pieza
2717	25301225	010.000.4097.00 Irbesartan - hidroclorotiazida	Pieza
2718	25301226	010.000.4098.00 Irbesartan - hidroclorotiazida	Pieza
2719	25301227	010.000.4095.00 Irbesartan	Pieza
2720	25301228	010.000.4096.00 Irbesartan	Pieza
2721	25301231	010.000.5444.00 Irinotecan	Pieza
2722	25301233	010.000.2024.00 Isoconazol	Pieza
2723	25301235	010.000.0232.00 Isoflurano	Pieza
2724	25301237	010.000.2416.00 Isoniazida - etambutol	Pieza
2725	25301238	010.000.2415.00 Isoniazida - rifampicina	Pieza
2726	25301239	010.000.2417.00 Isoniazida - rifampicina	Pieza
2727	25301240	010.000.2418.00 Isoniazida - rifampicina-pirazinamida - etambutol	Pieza
2728	25301241	010.000.2404.00 Isoniazida	Pieza
2729	25301246	010.000.2115.00 Isoprenalina	Pieza
2730	25301248	010.000.4118.00 Isosorbida dinitrato de	Pieza
2731	25301249	010.000.4120.00 Isosorbida mononitrato de	Pieza
2732	25301250	010.000.4121.00 Isosorbida mononitrato de	Pieza
2733	25301251	010.000.0593.00 Isosorbida	Pieza
2734	25301252	010.000.0592.00 Isosorbida	Pieza
2735	25301256	040.000.4129.00 Isotretinoina	Pieza
2736	25301258	010.000.2018.00 Itraconazol	Pieza
2737	25301260	010.000.1951.00 Kanamicina	Pieza
2738	25301262	040.000.0226.00 Ketamina	Pieza
2739	25301264	010.000.2016.00 Ketoconazol	Pieza
2740	25301266	010.000.2504.00 Ketoprofeno	Pieza
2741	25301270	010.000.0463.00 Ketotifeno	Pieza
2742	25301272	010.000.4268.00 Lamivudina - Zidovudina	Pieza
2743	25301273	010.000.4271.00 Lamivudina	Pieza
2744	25301277	010.000.5356.00 Lamotrigina	Pieza
2745	25301278	010.000.5358.00 Lamotrigina	Pieza
2746	25301280	010.000.0909.00 Lanolina y aceite mineral	Pieza
2747	25301282	010.000.5547.00 Laronidasa	Pieza
2748	25301289	010.000.2167.00 Leche descremada	Pieza
2749	25301293	010.000.2122.00 Lecitina vegetal	Pieza
2750	25301294	010.000.2121.00 Lecitina vegetal	Pieza
2751	25301296	010.000.4515.00 Leflunomida	Pieza
2752	25301297	010.000.4514.00 Leflunomida	Pieza
2753	25301299	010.000.5541.00 Letrozol	Pieza
2754	25301302	010.000.5434.00 Leuprorelina	Pieza
2755	25301303	010.000.5431.00 Leuprorelina	Pieza
2756	25301306	010.000.5502.00 Levamisol	Pieza
2757	25301308	010.000.2616.00 Levetiracetam	Pieza
2758	25301309	010.000.2618.00 Levetiracetam	Pieza
2759	25301310	010.000.2617.00 Levetiracetam	Pieza
2760	25301311	010.000.2180.00 Levobunolol/alcohol polivinilico	Pieza
2761	25301314	010.000.2181.00 Levocabastina	Pieza
2762	25301317	010.000.2171.00 Levocarnitina	Pieza
2763	25301319	010.000.3150.00 Levocetirizina	Pieza
2764	25301324	010.000.2182.00 Levoepinefrina	Pieza
2765	25301326	010.000.4249.00 Levofloxacino	Pieza
2766	25301327	010.000.4299.00 Levofloxacino	Pieza
2767	25301328	010.000.4300.00 Levofloxacino	Pieza
2768	25301330	040.000.5476.00 Levomepromazina	Pieza
2769	25301331	040.000.3204.00 Levomepromazina	Pieza
2770	25301333	010.000.2210.00 Levonorgestrel	Pieza
2771	25301334	010.000.4526.00 Levonorgestrel	Pieza
2772	25301335	010.000.2208.00 Levonorgestrel	Pieza
2773	25301337	010.000.3504.00 Levonorgestrel y etinilestradiol	Pieza
2774	25301338	010.000.3507.00 Levonorgestrel y etinilestradiol	Pieza
2775	25301342	010.000.1007.00 Levotiroxina	Pieza
2776	25301345	010.000.1364.00 Lidocaina - hidrocortisona	Pieza
2777	25301346	010.000.1363.00 Lidocaina - hidrocortisona	Pieza
2778	25301348	010.000.0264.00 Lidocaina	Pieza
2779	25301349	010.000.0522.00 Lidocaina	Pieza
2780	25301351	010.000.0261.00 Lidocaina	Pieza
2781	25301352	010.000.0262.00 Lidocaina	Pieza
2782	25301353	010.000.0263.00 Lidocaina	Pieza
2783	25301355	010.000.0265.00 Lidocaina, epinefrina	Pieza
2784	25301358	010.000.4527.00 Linestrenol	Pieza
2785	25301361	010.000.4291.00 Linezolid	Pieza
2786	25301362	010.000.4290.00 Linezolid	Pieza
2787	25301364	010.000.2731.00 Lipidos intravenosos	Pieza
2788	25301365	010.000.2744.00 Lipidos intravenosos	Pieza
2789	25301367	010.000.2740.00 Lipidos intravenosos	Pieza
2790	25301372	040.000.3255.00 Litio	Pieza
2791	25301374	010.000.4428.00 Lomustina	Pieza
2792	25301376	010.000.4184.00 Loperamida	Pieza
2793	25301378	010.000.5276.00 Lopinavir-Ritonavir	Pieza
2794	25301379	010.000.5288.00 Lopinavir-Ritonavir	Pieza
2795	25301381	010.000.2145.00 Loratadina	Pieza
2796	25301382	010.000.2144.00 Loratadina	Pieza
2797	25301384	040.000.5478.00 Lorazepam	Pieza
2798	25301387	010.000.3826.00 L-ornitina-L-aspartato	Pieza
2799	25301390	010.000.2521.00 Losartan e hidroclorotiazida	Pieza
2800	25301391	010.000.2520.00 Losartan	Pieza
2801	25301396	010.000.3629.00 Magnesio sulfato de	Pieza
2802	25301397	010.000.1275.00 Magnesio	Pieza
2803	25301399	010.000.5378.00 Manganeso	Pieza
2804	25301402	010.000.2306.00 Manitol	Pieza
2805	25301405	010.000.2136.00 Mebendazol	Pieza
2806	25301407	010.000.5447.00 Mecloretamina	Pieza
2807	25301409	010.000.2183.00 Medrisona	Pieza
2808	25301411	010.000.3045.00 Medroxiprogesterona	Pieza
2809	25301412	010.000.3044.00 Medroxiprogesterona	Pieza
2810	25301414	010.000.3509.00 Medroxiprogesterona y cipionato de estradiol	Pieza
2811	25301416	010.000.5464.00 Megestrol	Pieza
2812	25301417	010.000.5430.00 Megestrol	Pieza
2813	25301419	010.000.1756.00 Melfalan	Pieza
2814	25301421	010.000.3421.00 Meloxicam	Pieza
2815	25301422	010.000.3423.00 Meloxicam	Pieza
2816	25301424	010.000.1733.00 Menadiona	Pieza
2817	25301426	010.000.1761.00 Mercaptopurina	Pieza
2818	25301433	010.000.4189.00 Mesalazina	Pieza
2819	25301434	010.000.1244.00 Mesalazina	Pieza
2820	25301436	010.000.4433.00 Mesna	Pieza
2821	25301438	010.000.1062.00 Mesterolona	Pieza
2822	25301440	010.000.1503.00 Mestranol	Pieza
2823	25301442	010.000.0108.00 Metamizol sodico	Pieza
2824	25301443	010.000.0109.00 Metamizol sodico	Pieza
2825	25301445	010.000.2333.00 Metenamina	Pieza
2826	25301447	040.000.1710.00 Metenolona	Pieza
2827	25301449	010.000.5165.00 Metformina	Pieza
2828	25301451	010.000.0566.00 Metildopa	Pieza
2829	25301453	040.000.5351.00 Metilfenidato	Pieza
2830	25301458	010.000.0476.00 Metilprednisolona	Pieza
2831	25301459	010.000.3433.00 Metilprednisolona	Pieza
2832	25301460	010.000.2231.00 Metiltionino cloruro de (azul de metileno)	Pieza
2833	25301463	010.000.3444.00 Metocarbamol	Pieza
2834	25301465	010.000.1243.00 Metoclopramida	Pieza
2835	25301466	010.000.1241.00 Metoclopramida	Pieza
2836	25301467	010.000.1242.00 Metoclopramida	Pieza
2837	25301469	010.000.0572.00 Metoprolol	Pieza
2838	25301471	010.000.2194.00 Metotrexato	Pieza
2839	25301472	010.000.1760.00 Metotrexato	Pieza
2840	25301473	010.000.1776.00 Metotrexato	Pieza
2841	25301474	010.000.1759.00 Metotrexato	Pieza
2842	25301476	010.000.5126.00 Metoxaleno	Pieza
2843	25301478	010.000.1561.00 Metronidazol	Pieza
2844	25301479	010.000.1309.00 Metronidazol	Pieza
2845	25301480	010.000.1311.00 Metronidazol	Pieza
2846	25301481	010.000.1310.00 Metronidazol	Pieza
2847	25301484	010.000.0891.00 Miconazol	Pieza
2848	25301487	040.000.4057.00 Midazolam	Pieza
2849	25301488	040.000.2108.00 Midazolam	Pieza
2850	25301489	040.000.4060.00 Midazolam	Pieza
2851	25301490	040.000.2109.00 Midazolam	Pieza
2852	25301492	010.000.0091.00 Miel de maiz	Pieza
2853	25301494	010.000.5100.00 Milrinona	Pieza
2854	25301500	010.000.5490.00 Mirtazapina	Pieza
2855	25301502	010.000.3022.00 Mitomicina	Pieza
2856	25301504	010.000.4233.00 Mitoxantrona	Pieza
2857	25301512	010.000.4141.00 Mometasona	Pieza
2858	25301513	010.000.4132.00 Mometasona	Pieza
2859	25301515	010.000.4329.00 Montelukast	Pieza
2860	25301516	010.000.4330.00 Montelukast	Pieza
2861	25301519	040.000.2103.00 Morfina	Pieza
2862	25301520	040.000.2099.00 Morfina	Pieza
2863	25301521	040.000.2102.00 Morfina	Pieza
2864	25301522	040.000.4029.00 Morfina	Pieza
2865	25301526	010.000.4253.00 Moxifloxacino	Pieza
2866	25301527	010.000.4252.00 Moxifloxacino	Pieza
2867	25301534	010.000.2123.00 Mupirocina	Pieza
2868	25301536	010.000.4221.00 Nadroparina	Pieza
2869	25301538	010.000.4223.00 Nadroparina	Pieza
2870	25301539	010.000.4222.00 Nadroparina	Pieza
2871	25301541	010.000.2804.00 Nafazolina	Pieza
2872	25301545	010.000.0302.00 Naloxona	Pieza
2873	25301546	040.000.0302.00 Naloxona	Pieza
2874	25301548	010.000.3419.00 Naproxeno	Pieza
2875	25301549	010.000.3407.00 Naproxeno	Pieza
2876	25301551	010.000.4176.00 Neomicina	Pieza
2877	25301553	010.000.2824.00 Neomicina, polimixina B y bacitracina	Pieza
2878	25301555	010.000.2823.00 Neomicina, polimixina B y gramicidina	Pieza
2879	25301557	010.000.3132.00 Neomicina, polimixina B, fluocinolona y lidocaina	Pieza
2880	25301560	010.000.0291.00 Neostigmina	Pieza
2881	25301561	010.000.2110.00 Neostigmina	Pieza
2882	25301563	010.000.4200.00 Nesiritida	Pieza
2883	25301565	010.000.5259.00 Nevirapina	Pieza
2884	25301570	010.000.0084.00 Nicotina	Pieza
2885	25301571	010.000.0082.00 Nicotina	Pieza
2886	25301572	010.000.0083.00 Nicotina	Pieza
2887	25301573	010.000.0081.00 Nicotina	Pieza
2888	25301574	010.000.0080.00 Nicotina	Pieza
2889	25301576	010.000.0597.00 Nifedipino	Pieza
2890	25301577	010.000.0599.00 Nifedipino	Pieza
2891	25301579	010.000.4322.00 Nilotinib	Pieza
2892	25301581	010.000.5424.00 Nilutamida	Pieza
2893	25301583	010.000.5354.00 Nimodipino	Pieza
2894	25301585	010.000.1566.00 Nistatina	Pieza
2895	25301586	010.000.4260.00 Nistatina	Pieza
2896	25301590	010.000.2519.00 Nitazoxanida	Pieza
2897	25301592	010.000.1562.00 Nitrofural	Pieza
2898	25301594	010.000.1911.00 Nitrofurantoina	Pieza
2899	25301595	010.000.5302.00 Nitrofurantoina	Pieza
2900	25301597	010.000.0569.00 Nitroprusiato de sodio	Pieza
2901	25301598	010.000.3511.00 Norelgestromina y etinilestradiol	Pieza
2902	25301601	010.000.0612.00 Norepinefrina	Pieza
2903	25301603	010.000.3503.00 Noretisterona	Pieza
2904	25301605	010.000.3515.00 Noretisterona y estradiol	Pieza
2905	25301607	010.000.3506.00 Noretisterona y etinilestradiol	Pieza
2906	25301609	010.000.2184.00 Norfloxacino	Pieza
2907	25301611	010.000.2733.00 Nutricion parenteral	Pieza
2908	25301612	010.000.2734.00 Nutricion parenteral	Pieza
2909	25301613	010.000.2730.00 Nutricion parenteral	Pieza
2910	25301615	010.000.5181.00 Octreotida	Pieza
2911	25301621	010.000.4489.00 Olanzapina	Pieza
2912	25301625	010.000.5381.00 Oligometales endovenosos	Pieza
2913	25301627	010.000.4340.00 Omalizumab	Pieza
2914	25301632	010.000.5428.00 Ondansetron	Pieza
2915	25301633	010.000.2195.00 Ondansetron	Pieza
2916	25301636	010.000.4436.00 Oprelvekina	Pieza
2917	25301638	010.000.1551.00 Orciprenalina	Pieza
2918	25301639	010.000.1552.00 Orciprenalina	Pieza
2919	25301642	010.000.3443.00 Orfenadrina	Pieza
2920	25301644	010.000.4582.00 Oseltamivir	Pieza
2921	25301647	010.000.5459.00 Oxaliplatino	Pieza
2922	25301648	010.000.5458.00 Oxaliplatino	Pieza
2923	25301650	010.000.2626.00 Oxcarbazepina	Pieza
2924	25301651	010.000.2627.00 Oxcarbazepina	Pieza
2925	25301652	010.000.2628.00 Oxcarbazepina	Pieza
2926	25301659	010.000.0804.00 Oxido de zinc	Pieza
2927	25301661	010.000.2199.00 Oximetazolina	Pieza
2928	25301662	010.000.2198.00 Oximetazolina	Pieza
2929	25301666	010.000.2137.00 Oxitetraciclina	Pieza
2930	25301669	010.000.1542.00 Oxitocina	Pieza
2931	25301671	010.000.5435.00 Paclitaxel	Pieza
2932	25301673	010.000.2124.00 Padimato, parsol mcx y parsol 1789	Pieza
2933	25301675	010.000.4321.00 Palivizumab	Pieza
2934	25301676	010.000.4320.00 Palivizumab	Pieza
2935	25301678	010.000.4437.00 Palonosetron	Pieza
2936	25301680	010.000.4190.00 Pancreatina	Pieza
2937	25301685	010.000.0106.00 Paracetamol	Pieza
2938	25301687	010.000.0105.00 Paracetamol	Pieza
2939	25301688	010.000.0104.00 Paracetamol	Pieza
2940	25301692	010.000.1100.00 Paricalcitol	Pieza
2941	25301694	010.000.5481.00 Paroxetina	Pieza
2942	25301696	010.000.5452.00 Pegfilgrastim	Pieza
2943	25301699	010.000.5224.00 Peginterferon alfa-2b	Pieza
2944	25301700	010.000.5222.00 Peginterferon alfa-2b	Pieza
2945	25301701	010.000.5221.00 Peginterferon alfa-2b	Pieza
2946	25301703	010.000.5453.00 Pemetrexed	Pieza
2947	25301705	010.000.2202.00 Penicilamina	Pieza
2948	25301708	010.000.5328.00 Pentamidina	Pieza
2949	25301711	010.000.4117.00 Pentoxifilina	Pieza
2950	25301713	040.000.3247.00 Perfenazina	Pieza
2951	25301716	010.000.2851.00 Pilocarpina	Pieza
2952	25301717	010.000.2852.00 Pilocarpina	Pieza
2953	25301723	010.000.4149.00 Pioglitazona	Pieza
2954	25301724	010.000.4592.00 Piperacilina  tazobactam	Pieza
2955	25301727	010.000.2138.00 Pirantel	Pieza
2956	25301729	010.000.2413.00 Pirazinamida	Pieza
2957	25301731	010.000.2662.00 Piridostigmina	Pieza
2958	25301733	010.000.5232.00 Piridoxina	Pieza
2959	25301735	010.000.5261.00 Pirimetamina	Pieza
2960	25301737	010.000.3415.00 Piroxicam	Pieza
2961	25301739	010.000.2150.00 Plantago ovata - senosidos A y B	Pieza
2962	25301741	010.000.1271.00 Plantago psyllium	Pieza
2963	25301743	010.000.0901.00 Podofilina	Pieza
2964	25301747	010.000.4113.00 Polidocanol	Pieza
2965	25301749	010.000.4191.00 Polietilenglicol	Pieza
2966	25301751	010.000.3661.00 Poligelina	Pieza
2967	25301752	010.000.3664.00 Polimerizado de gelatina	Pieza
2968	25301753	010.000.0523.00 Potasio sales de	Pieza
2969	25301756	010.000.2649.00 Pramipexol	Pieza
2970	25301757	010.000.2650.00 Pramipexol	Pieza
2971	25301759	010.000.0657.00 Pravastatina	Pieza
2972	25301761	010.000.1346.00 Prazicuantel	Pieza
2973	25301762	010.000.2040.00 Prazicuantel	Pieza
2974	25301764	010.000.0573.00 Prazosina	Pieza
2975	25301767	010.000.2841.00 Prednisolona	Pieza
2976	25301768	010.000.2482.00 Prednisolona	Pieza
2977	25301769	010.000.2185.00 Prednisolona	Pieza
2978	25301772	010.000.0472.00 Prednisona	Pieza
2979	25301775	010.000.0473.00 Prednisona	Pieza
2980	25301782	010.000.2032.00 Primaquina	Pieza
2981	25301783	010.000.2031.00 Primaquina	Pieza
2982	25301785	010.000.2607.00 Primidona	Pieza
2983	25301786	010.000.2606.00 Primidona	Pieza
2984	25301788	010.000.3453.00 Probenecid	Pieza
2985	25301790	010.000.1771.00 Procarbazina	Pieza
2986	25301793	010.000.4215.00 Progesterona	Pieza
2987	25301794	010.000.4207.00 Progesterona	Pieza
2988	25301795	010.000.4217.00 Progesterona	Pieza
2989	25301797	010.000.0537.00 Propafenona	Pieza
2990	25301799	010.000.0246.00 Propofol	Pieza
2991	25301801	010.000.0245.00 Propofol	Pieza
2992	25301803	010.000.2117.00 Propranolol	Pieza
2993	25301804	010.000.0539.00 Propranolol	Pieza
2994	25301805	010.000.0530.00 Propranolol	Pieza
2995	25301807	010.000.0625.00 Protamina	Pieza
2996	25301810	010.000.2891.00 Proximetacaina	Pieza
2997	25301814	010.000.5489.00 Quetiapina	Pieza
2998	25301817	010.000.1314.00 Quinfamida	Pieza
2999	25301819	010.000.0527.00 Quinidina	Pieza
3000	25301821	010.000.2034.00 Quinina	Pieza
3001	25301822	010.000.5312.00 Quinupristina - dalfopristina	Pieza
3002	25301827	010.000.5280.00 Raltegravir	Pieza
3003	25301829	010.000.5425.00 Raltitrexed	Pieza
3004	25301833	010.000.1233.00 Ranitidina	Pieza
3005	25301834	010.000.2151.00 Ranitidina	Pieza
3006	25301837	010.000.4487.00 Reboxetina	Pieza
3007	25301840	040.000.0248.00 Remifentanilo	Pieza
3008	25301842	010.000.4112.00 Resina de colestiramina	Pieza
3009	25301844	010.000.2139.00 Ribavirina	Pieza
3010	25301846	010.000.2414.00 Rifampicina  isoniazida - pirazinamida	Pieza
3011	25301847	010.000.2409.00 Rifampicina	Pieza
3012	25301848	010.000.2410.00 Rifampicina	Pieza
3013	25301851	010.000.4581.00 Rimantadina	Pieza
3014	25301852	010.000.4580.00 Rimantadina	Pieza
3015	25301856	040.000.3262.00 Risperidona	Pieza
3016	25301857	040.000.3268.00 Risperidona	Pieza
3017	25301858	040.000.3258.00 Risperidona	Pieza
3018	25301868	010.000.4059.00 Rocuronio, Bromuro de	Pieza
3019	25301870	010.000.0270.00 Ropivacaina	Pieza
3020	25301871	010.000.0269.00 Ropivacaina	Pieza
3021	25301876	010.000.2140.00 Roxitromicina	Pieza
3022	25301878	010.000.1714.00 Sacarato ferrico	Pieza
3023	25301880	010.000.0431.00 Salbutamol	Pieza
3024	25301881	010.000.0439.00 Salbutamol	Pieza
3025	25301882	010.000.0429.00 Salbutamol	Pieza
3026	25301884	010.000.0442.00 Salmeterol - Fluticasona	Pieza
3027	25301885	010.000.0441.00 Salmeterol	Pieza
3028	25301887	010.000.0443.00 Salmeterol, Fluticasona	Pieza
3029	25301889	010.000.5290.00 Saquinavir	Pieza
3030	25301891	010.000.4378.00 Selenio	Pieza
3031	25301893	010.000.1270.00 Senosidos A-B	Pieza
3032	25301894	010.000.1272.00 Senosidos A-B	Pieza
3033	25301896	010.000.4552.00 Seroalbumina humana o albumina humana	Pieza
3034	25301897	010.000.3662.00 Seroalbumina humana o albumina humana	Pieza
3035	25301899	040.000.4484.00 Sertralina	Pieza
3036	25301901	010.000.5160.00 Sevelamero	Pieza
3037	25301912	010.000.5087.00 Sirolimus	Pieza
3038	25301913	010.000.5086.00 Sirolimus	Pieza
3039	25301915	010.000.2366.00 Sistema integral para la aplicacion de dialisis peritoneal automatizada	Pieza
3040	25301917	010.000.2365.00 Sistema integral para la aplicacion de dialisis peritoneal continua ambulatoria	Pieza
3041	25301921	010.000.2505.00 Sodio bicarbonato de /potasio cloruro de	Pieza
3042	25301924	010.000.3616.00 Solucion Hartmann	Pieza
3043	25301925	010.000.3614.00 Solucion Hartmann	Pieza
3044	25301926	010.000.3615.00 Solucion Hartmann	Pieza
3045	25301931	010.000.2360.00 Solucion para dialisis peritoneal con aminoacidos	Pieza
3046	25301932	010.000.2361.00 Solucion para dialisis peritoneal con aminoacidos	Pieza
3047	25301934	010.000.2364.00 Solucion para dialisis peritoneal con icodextrina	Pieza
3048	25301935	010.000.2363.00 Solucion para dialisis peritoneal con icodextrina	Pieza
3049	25301937	010.000.2348.00 Solucion para dialisis peritoneal con sistema de doble bolsa	Pieza
3050	25301938	010.000.2349.00 Solucion para dialisis peritoneal con sistema de doble bolsa	Pieza
3051	25301940	010.000.2341.00 Solucion para dialisis peritoneal	Pieza
3052	25301941	010.000.2350.00 Solucion para dialisis peritoneal	Pieza
3053	25301942	010.000.2356.00 Solucion para dialisis peritoneal	Pieza
3054	25301943	010.000.2357.00 Solucion para dialisis peritoneal	Pieza
3055	25301944	010.000.2342.00 Solucion para dialisis peritoneal	Pieza
3056	25301945	010.000.2346.00 Solucion para dialisis peritoneal	Pieza
3057	25301946	010.000.2352.00 Solucion para dialisis peritoneal	Pieza
3058	25301947	010.000.2353.00 Solucion para dialisis peritoneal	Pieza
3059	25301948	010.000.2351.00 Solucion para dialisis peritoneal	Pieza
3060	25301949	010.000.2354.00 Solucion para dialisis peritoneal	Pieza
3061	25301950	010.000.2358.00 Solucion para dialisis peritoneal	Pieza
3062	25301951	010.000.2355.00 Solucion para dialisis peritoneal	Pieza
3063	25301952	010.000.2344.00 Solucion para dialisis peritoneal	Pieza
3064	25301953	010.000.2517.00 Solucion para dialisis peritoneal	Pieza
3065	25301954	010.000.2343.00 Solucion para dialisis peritoneal	Pieza
3066	25301958	010.000.5172.00 Somatostina	Pieza
3067	25301961	010.000.5163.00 Somatropina	Pieza
3068	25301965	010.000.5480.00 Sorafenib	Pieza
3069	25301967	030.000.0003.00 Sucedaneo de leche humana de pretermino	Pieza
3070	25301969	030.000.0011.00 Sucedaneo de leche humana de termino	Pieza
3071	25301971	030.000.0012.00 Sucedaneo de leche humana de termino sin lactosa	Pieza
3072	25301973	010.000.5176.00 Sucralfato	Pieza
3073	25301975	020.000.3842.00 Suero antialacran	Pieza
3074	25301977	020.000.3844.00 Suero antirrabico equino	Pieza
3075	25301979	020.000.3843.00 Suero antiviperino	Pieza
3076	25301982	010.000.2829.00 Sulfacetamida	Pieza
3077	25301984	010.000.4126.00 Sulfadiazina de plata	Pieza
3078	25301987	010.000.4504.00 Sulfasalazina	Pieza
3079	25301989	010.000.1704.00 Sulfato ferroso	Pieza
3080	25301990	010.000.1703.00 Sulfato ferroso	Pieza
3081	25301992	010.000.5503.00 Sulindaco	Pieza
3082	25301994	010.000.4357.00 Sumatriptan	Pieza
3083	25301996	010.000.5482.00 Sunitinib	Pieza
3084	25301998	010.000.0252.00 Suxametonio, Cloruro de	Pieza
3085	25302000	010.000.4130.00 Tacalcitol	Pieza
3086	25302008	010.000.4256.00 Talidomida	Pieza
3087	25302010	010.000.3047.00 Tamoxifeno	Pieza
3088	25302016	010.000.4194.00 Tegaserod	Pieza
3089	25302018	010.000.5278.00 Teicoplanina	Pieza
3090	25302019	010.000.4578.00 Teicoplanina	Pieza
3091	25302021	010.000.2542.00 Telmisartan  hidroclorotiazida	Pieza
3092	25302022	010.000.2540.00 Telmisartan	Pieza
3093	25302028	010.000.5117.00 Tenecteplasa	Pieza
3094	25302032	010.000.0437.00 Teofilina	Pieza
3095	25302033	010.000.5075.00 Teofilina	Pieza
3096	25302035	010.000.2513.00 Terazosina	Pieza
3097	25302037	010.000.0438.00 Terbutalina	Pieza
3098	25302038	010.000.0432.00 Terbutalina	Pieza
3099	25302039	010.000.0433.00 Terbutalina	Pieza
3100	25302042	010.000.5191.00 Terlipresina	Pieza
3101	25302045	010.000.1061.00 Testosterona	Pieza
3102	25302047	010.000.4407.00 Tetracaina	Pieza
3103	25302049	010.000.1981.00 Tetraciclina	Pieza
3104	25302051	010.000.1022.00 Tiamazol	Pieza
3105	25302053	010.000.5395.00 Tiamina	Pieza
3106	25302057	010.000.5454.00 Tietilperazina	Pieza
3107	25302059	010.000.4590.00 Tigeciclina	Pieza
3108	25302061	010.000.2858.00 Timolol	Pieza
3109	25302063	010.000.2042.00 Tinidazol	Pieza
3110	25302065	040.000.0221.00 Tiopental sodico	Pieza
3111	25302067	010.000.3001.00 Tiotepa	Pieza
3112	25302069	010.000.2263.00 Tiotropio, bromuro de	Pieza
3113	25302070	010.000.2262.00 Tiotropio, bromuro de	Pieza
3114	25302072	010.000.4274.00 Tipranavir	Pieza
3115	25302074	010.000.4123.00 Tirofiban	Pieza
3116	25302078	010.000.5140.00 Tirotropina alfa	Pieza
3117	25302080	010.000.1005.00 Tiroxina/ Triyodotironina	Pieza
3118	25302084	010.000.1041.00 Tolbutamida	Pieza
3119	25302088	010.000.5366.00 Topiramato	Pieza
3120	25302092	010.000.4362.00 Toxina botulinica tipo A	Pieza
3121	25302093	010.000.4352.00 Toxina botulinica tipo A	Pieza
3122	25302097	040.000.2106.00 Tramadol	Pieza
3123	25302099	040.000.2096.00 Tramadol-paracetamol	Pieza
3124	25302102	010.000.5422.00 Trastuzumab	Pieza
3125	25302103	010.000.5423.00 Trastuzumab	Pieza
3126	25302105	010.000.4418.00 Travoprost	Pieza
3127	25302107	010.000.5436.00 Tretinoina	Pieza
3128	25302108	010.000.4137.00 Tretinoina	Pieza
3129	25302110	040.000.3206.00 Triazolam	Pieza
3130	25302114	040.000.2651.00 Trihexifenidilo	Pieza
3131	25302115	010.000.5255.00 Trimetoprima - sulfametoxazol	Pieza
3132	25302116	010.000.1904.00 Trimetoprima - sulfametoxazol	Pieza
3133	25302117	010.000.1903.00 Trimetoprima - sulfametoxazol	Pieza
3134	25302121	010.000.0591.00 Trinitrato de glicerilo	Pieza
3135	25302122	010.000.4111.00 Trinitrato de glicerilo	Pieza
3136	25302123	010.000.4114.00 Trinitrato de glicerilo	Pieza
3137	25302127	010.000.5427.00 Tropisetron	Pieza
3138	25302131	010.000.5204.00 Urofolitropina	Pieza
3139	25302142	020.000.3813.00 Vacuna antipertussis con toxoides difterico y Tetanico (DPT)	Pieza
3140	25302143	020.000.3805.00 Vacuna antipertussis con toxoides difterico y tetanico (DPT)	Pieza
3141	25302145	020.000.3803.00 Vacuna antipoliomielitica inactivada	Pieza
3142	25302150	020.000.3818.00 Vacuna antirrabica	Pieza
3143	25302152	020.000.0153.00 Vacuna antirrubeola	Pieza
3144	25302154	020.000.3815.00 Vacuna antisarampion	Pieza
3145	25302156	020.000.3806.00 Vacuna antitifoidica inactivada	Pieza
3146	25302158	020.000.3819.00 Vacuna atenuada contra varicela	Pieza
3147	25302164	020.000.3828.00 Vacuna contra difteria, tos ferina, tetanos, hepatitis B, poliomielitis y Haemophilus influenza tipo b	Pieza
3148	25302176	020.000.3804.00 Vacuna doble viral (SR) contra sarampion y rubeola Vacuna doble viral (SR) contra sarampion y rubeola	Pieza
3149	25302180	020.000.0152.00 Vacuna Pentavalente contra rotavirus	Pieza
3150	25302181	020.000.2526.00 Vacuna recombinante contra Hepatitis B	Pieza
3151	25302182	020.000.2511.00 Vacuna recombinante contra Hepatitis B	Pieza
3152	25302184	020.000.2527.00 Vacuna recombinante contra la Hepatitis B	Pieza
3153	25302187	020.000.3821.00 Vacuna triple viral (SRP) contra sarampion, rubeola y parotiditis	Pieza
3154	25302188	020.000.3820.00 Vacuna triple viral (SRP) contra sarampion, rubeola y parotiditis	Pieza
3155	25302192	010.000.4373.00 Valganciclovir	Pieza
3156	25302194	010.000.2623.00 Valproato de magnesio	Pieza
3157	25302195	010.000.2622.00 Valproato de magnesio	Pieza
3158	25302196	010.000.5359.00 Valproato de magnesio	Pieza
3159	25302198	010.000.5471.00 Valproato semisodico	Pieza
3160	25302199	010.000.5488.00 Valproato semisodico	Pieza
3161	25302200	010.000.2630.00 Valproato semisodico	Pieza
3162	25302202	010.000.5111.00 Valsartan	Pieza
3163	25302204	010.000.4251.00 Vancomicina	Pieza
3164	25302209	010.000.0085.00 Vareniclina	Pieza
3165	25302210	010.000.0086.00 Vareniclina	Pieza
3166	25302215	010.000.4154.00 Vasopresina	Pieza
3167	25302220	010.000.0254.00 Vecuronio	Pieza
3168	25302222	010.000.4488.00 Venlafaxina	Pieza
3169	25302224	010.000.0596.00 Verapamilo	Pieza
3170	25302225	010.000.0598.00 Verapamilo	Pieza
3171	25302227	010.000.4415.00 Verteporfina	Pieza
3172	25302229	010.000.5355.00 Vigabatrina	Pieza
3173	25302231	010.000.1770.00 Vinblastina	Pieza
3174	25302233	010.000.1768.00 Vincristina	Pieza
3175	25302235	010.000.4445.00 Vinorelbina	Pieza
3176	25302236	010.000.4446.00 Vinorelbina	Pieza
3177	25302237	010.000.4435.00 Vinorelbina	Pieza
3178	25302240	010.000.2191.00 Vitamina A	Pieza
3179	25302247	010.000.1098.00 Vitaminas A.C.D	Pieza
3180	25302249	010.000.2712.00 Vitaminas y minerales	Pieza
3181	25302250	010.000.2711.00 Vitaminas y minerales	Pieza
3182	25302251	010.000.2709.00 Vitaminas y minerales	Pieza
3183	25302252	010.000.2716.00 Vitaminas y minerales	Pieza
3184	25302253	010.000.2717.00 Vitaminas y minerales	Pieza
3185	25302256	010.000.5315.00 Voriconazol	Pieza
3186	25302257	010.000.5318.00 Voriconazol	Pieza
3187	25302258	010.000.5317.00 Voriconazol	Pieza
3188	25302260	010.000.0623.00 Warfarina	Pieza
3189	25302263	010.000.4331.00 Zafirlukast	Pieza
3190	25302265	010.000.4374.00 Zanamivir	Pieza
3191	25302267	010.000.4257.00 Zidovudina	Pieza
3192	25302268	010.000.5274.00 Zidovudina	Pieza
3193	25302269	010.000.5273.00 Zidovudina	Pieza
3194	25302271	010.000.5379.00 Zinc	Pieza
3195	25302273	010.000.2801.00 Zinc y fenilefrina	Pieza
3196	25302275	010.000.3264.00 Ziprasidona	Pieza
3197	25302276	010.000.3265.00 Ziprasidona	Pieza
3198	25302280	010.000.5483.00 Zuclopentixol	Pieza
3199	25302298	010.000.6000.00 Carbonato de calcio / Vitamina D3	Pieza
3200	25302299	010.000.5835.00 Cinacalcet	Pieza
3201	25302300	010.000.5935.00 Dabigatran	Pieza
3202	25302301	010.000.5552.00 Dabigatran etexilato	Pieza
3203	25302302	010.000.5552.01 Dabigatran etexilato	Pieza
3204	25302303	010.000.5551.00 Dabigatran etexilato	Pieza
3205	25302304	010.000.5551.01 Dabigatran etexilato	Pieza
3206	25302305	010.000.5930.00 Darbepoetina alfa	Pieza
3207	25302306	010.000.5629.00 Darbepoetina alfa	Pieza
3208	25302307	010.000.5625.00 Darbepoetina alfa	Pieza
3209	25302308	010.000.5626.00 Darbepoetina alfa	Pieza
3210	25302309	010.000.5632.00 Darbepoetina alfa	Pieza
3211	25302310	010.000.5627.00 Darbepoetina alfa	Pieza
3212	25302311	010.000.5633.00 Darbepoetina alfa	Pieza
3213	25302312	010.000.5628.00 Darbepoetina alfa	Pieza
3214	25302313	010.000.6010.00 Dolutegravir	Pieza
3215	25302314	010.000.5699.00 Etoricoxib	Pieza
3216	25302315	010.000.5815.00 Fingolimod	Pieza
3217	25302316	010.000.5880.00 Fulvestrant	Pieza
3218	25302317	010.000.5611.00 Lanreotido	Pieza
3219	25302318	010.000.5611.01 Lanreotido	Pieza
3220	25302319	010.000.5610.00 Lanreotido	Pieza
3221	25302320	010.000.5610.01 Lanreotido	Pieza
3222	25302321	010.000.5617.00 Lenalidomida	Pieza
3223	25302322	010.000.5618.00 Lenalidomida	Pieza
3224	25302323	010.000.5619.00 Lenalidomida	Pieza
3225	25302324	010.000.5616.00 Lenalidomida	Pieza
3226	25302325	010.000.5621.00 Linagliptina	Pieza
3227	25302326	010.000.5742.00 Linagliptina/Metformina	Pieza
3228	25302327	010.000.5740.00 Linagliptina/Metformina	Pieza
3229	25302328	010.000.5741.00 Linagliptina/Metformina	Pieza
3230	25302329	010.000.5743.00 Liraglutide	Pieza
3231	25302330	010.000.5257.00 Natalizumab	Pieza
3232	25302331	010.000.6037.00 Obinutuzumab	Pieza
3233	25302332	010.000.5655.00 Pazopanib	Pieza
3234	25302333	010.000.2642.01 Rotigotina	Pieza
3235	25302334	010.000.2642.00 Rotigotina	Pieza
3236	25302335	010.000.2643.01 Rotigotina	Pieza
3237	25302336	010.000.2643.00 Rotigotina	Pieza
3238	25302337	010.000.2640.00 Rotigotina	Pieza
3239	25302338	010.000.2641.02 Rotigotina	Pieza
3240	25302339	010.000.2641.01 Rotigotina	Pieza
3241	25302340	010.000.2641.00 Rotigotina	Pieza
3242	25302341	010.000.6047.00 Tocilizumab	Pieza
3243	25302342	010.000.4516.00 Tocilizumab	Pieza
3244	25302343	010.000.4513.00 Tocilizumab	Pieza
3245	25302344	020.000.0148.01 Vacuna conjugada neumococica 13-valente	Pieza
3246	25302345	020.000.0148.00 Vacuna conjugada neumococica 13-valente	Pieza
3247	25302346	010.000.5820.00 Abatacept	Pieza
3248	25302347	010.000.5790.00 Abatacept	Pieza
3249	25302348	010.000.5657.00 Abiraterona	Pieza
3250	25302349	010.000.3405.01 Acemetacina	Pieza
3251	25302350	010.000.3405.00 Acemetacina	Pieza
3252	25302351	010.000.3406.00 Acemetacina	Pieza
3253	25302352	010.000.3406.01 Acemetacina	Pieza
3254	25302353	010.000.0624.00 Acenocumarol	Pieza
3255	25302354	010.000.0624.01 Acenocumarol	Pieza
3256	25302356	010.000.6049.00 Acido acetilsalicilico, simvastatina, ramipril	Pieza
3257	25302357	010.000.6050.00 Acido acetilsalicilico, simvastatina, ramipril	Pieza
3258	25302358	010.000.1706.00 Acido folico	Pieza
3259	25302359	010.000.1706.01 Acido folico	Pieza
3260	25302360	010.000.4185.01 Acido ursodeoxicolico	Pieza
3261	25302361	010.000.4512.01 Adalimumab	Pieza
3262	25302362	010.000.4512.00 Adalimumab	Pieza
3263	25302363	010.000.4512.02 Adalimumab	Pieza
3264	25302364	010.000.5995.00 Aflibercept	Pieza
3265	25302365	010.000.5549.00 Agalsidasa alfa	Pieza
3266	25302366	010.000.2742.01 Alanina y Levoglutamina	Pieza
3267	25302367	010.000.2742.00 Alanina y Levoglutamina	Pieza
3268	25302368	010.000.5132.00 Alantoina, alquitran de hulla y clioquinol	Pieza
3269	25302369	010.000.5132.01 Alantoina, alquitran de hulla y clioquinol	Pieza
3270	25302472	010.000.3671.00 Cloruro de sodio	Pieza
3271	25302370	010.000.5408.00 Alimento medico para pacientes con enfermedad de orina de jarabe de maple (arce), de 8 años o mayores y adultos	Pieza
3272	25302371	010.000.3663.00 Almidon	Pieza
3273	25302372	010.000.3663.01 Almidon	Pieza
3274	25302373	010.000.3666.00 Almidon	Pieza
3275	25302374	010.000.3666.01 Almidon	Pieza
3276	25302375	010.000.5900.00 Almotriptan	Pieza
3277	25302376	010.000.2503.00 Alopurinol	Pieza
3278	25302377	010.000.2503.01 Alopurinol	Pieza
3279	25302378	010.000.5631.00 Alprostadil	Pieza
3280	25302379	010.000.6051.00 Alprostadil	Pieza
3281	25302380	010.000.1224.00 Aluminio  magnesio	Pieza
3282	25302381	010.000.1223.00 Aluminio  magnesio	Pieza
3283	25302382	010.000.2012.00 Amfotericina B o anfotericina B	Pieza
3284	25302383	010.000.1957.01 Amikacina	Pieza
3285	25302384	010.000.1957.00 Amikacina	Pieza
3286	25302385	010.000.1956.01 Amikacina	Pieza
3287	25302386	010.000.1956.00 Amikacina	Pieza
3288	25302387	010.000.2512.00 Aminoacidos cristalinos	Pieza
3289	25302388	010.000.2512.01 Aminoacidos cristalinos	Pieza
3290	25302390	010.000.2111.00 Amlodipino	Pieza
3291	25302391	010.000.2111.01 Amlodipino	Pieza
3292	25302392	010.000.5800.00 Amlodipino/Valsartan/Hidroclorotiazida	Pieza
3293	25302393	010.000.2230.00 Amoxicilina - acido clavulanico	Pieza
3294	25302394	010.000.2230.01 Amoxicilina - acido clavulanico	Pieza
3295	25302395	010.000.2128.00 Amoxicilina	Pieza
3296	25302396	010.000.2128.01 Amoxicilina	Pieza
3297	25302397	010.000.2127.00 Amoxicilina	Pieza
3298	25302398	040.000.4486.00 Anfebutamona	Pieza
3299	25302399	040.000.4486.01 Anfebutamona	Pieza
3300	25302400	010.000.5670.00 Anidulafungina	Pieza
3301	25302401	010.000.5731.00 Apixaban	Pieza
3302	25302402	010.000.5731.01 Apixaban	Pieza
3303	25302403	010.000.5732.00 Apixaban	Pieza
3304	25302404	010.000.5732.01 Apixaban	Pieza
3305	25302405	010.000.6043.00 Asunaprevir	Pieza
3306	25302406	010.000.6005.00 Axitinib	Pieza
3307	25302407	010.000.6006.00 Axitinib	Pieza
3308	25302408	010.000.5887.00 Azacitidina	Pieza
3309	25302409	010.000.5645.00 Azilsartan medoxomilo	Pieza
3310	25302410	010.000.5645.01 Azilsartan medoxomilo	Pieza
3311	25302411	010.000.1969.00 Azitromicina	Pieza
3312	25302412	010.000.1969.01 Azitromicina	Pieza
3313	25302413	010.000.0801.01 Baño coloide	Pieza
3314	25302414	010.000.0801.00 Baño coloide	Pieza
3315	25302415	010.000.5308.00 Basiliximab	Pieza
3316	25302416	010.000.5308.01 Basiliximab	Pieza
3317	25302417	010.000.2508.00 Beclometasona dipropionato de	Pieza
3318	25302418	010.000.5825.00 Belimumab	Pieza
3319	25302419	010.000.5826.00 Belimumab	Pieza
3320	25302420	010.000.5634.00 Bemiparina de sodio	Pieza
3321	25302421	010.000.0822.00 Benzoilo	Pieza
3322	25302422	010.000.0822.01 Benzoilo	Pieza
3323	25302423	010.000.0822.02 Benzoilo	Pieza
3324	25302424	010.000.5331.00 Beractant	Pieza
3325	25302425	010.000.5440.01 Bicalutamida	Pieza
3326	25302426	010.000.5440.00 Bicalutamida	Pieza
3327	25302427	010.000.5675.00 Boceprevir	Pieza
3328	25302428	010.000.5601.00 Bosentan	Pieza
3329	25302429	010.000.5600.00 Bosentan	Pieza
3330	25302430	010.000.6035.00 Bromuro de glicopirronio	Pieza
3331	25302431	010.000.4337.00 Budesonida	Pieza
3332	25302432	010.000.4332.01 Budesonida	Pieza
3333	25302433	010.000.4332.00 Budesonida	Pieza
3334	25302434	010.000.4333.01 Budesonida	Pieza
3335	25302435	010.000.4333.00 Budesonida	Pieza
3336	25302436	010.000.4055.00 Bupivacaina	Pieza
3337	25302437	040.000.6039.00 Buprenorfina	Pieza
3338	25302438	040.000.6038.00 Buprenorfina	Pieza
3339	25302439	040.000.2100.00 Buprenorfina	Pieza
3340	25302440	040.000.2100.01 Buprenorfina	Pieza
3341	25302441	010.000.1206.00 Butilhioscina o Hioscina	Pieza
3342	25302442	010.000.1207.00 Butilhioscina o Hioscina	Pieza
3343	25302443	010.000.5658.00 Cabazitaxel	Pieza
3344	25302444	010.000.1094.00 Cabergolina	Pieza
3345	25302445	010.000.1094.01 Cabergolina	Pieza
3346	25302446	010.000.5612.00 Calcipotriol, betametasona	Pieza
3347	25302447	010.000.5161.01 Calcitonina	Pieza
3348	25302448	010.000.5161.02 Calcitonina	Pieza
3349	25302449	010.000.5161.00 Calcitonina	Pieza
3350	25302450	010.000.1541.01 Carbetocina	Pieza
3351	25302451	010.000.1541.02 Carbetocina	Pieza
3352	25302452	010.000.1541.00 Carbetocina	Pieza
3353	25302453	010.000.5295.01 Cefepima	Pieza
3354	25302454	010.000.5295.00 Cefepima	Pieza
3355	25302455	010.000.5264.02 Cefuroxima	Pieza
3356	25302456	010.000.5264.00 Cefuroxima	Pieza
3357	25302457	010.000.5264.01 Cefuroxima	Pieza
3358	25302458	010.000.5795.00 Certolizumab Pegol	Pieza
3359	25302459	010.000.5475.01 Cetuximab	Pieza
3360	25302460	010.000.5475.00 Cetuximab	Pieza
3361	25302461	010.000.1751.00 Ciclofosfamida	Pieza
3362	25302462	010.000.1751.01 Ciclofosfamida	Pieza
3363	25302463	010.000.4307.00 Cilostazol	Pieza
3364	25302464	010.000.4259.00 Ciprofloxacino	Pieza
3365	25302465	010.000.5487.00 Citalopram	Pieza
3366	25302466	010.000.5487.01 Citalopram	Pieza
3367	25302467	010.000.4246.01 Clopidogrel	Pieza
3368	25302468	010.000.4246.00 Clopidogrel	Pieza
3369	25302469	010.000.5630.00 Clopidogrel, acido acetilsalicilico	Pieza
3370	25302470	010.000.2030.01 Cloroquina	Pieza
3371	25302471	010.000.3609.00 Cloruro de sodio	Pieza
3372	25302473	010.000.3626.00 Cloruro de sodio	Pieza
3373	25302474	010.000.3608.00 Cloruro de sodio	Pieza
3374	25302475	010.000.3611.00 Cloruro de sodio y glucosa	Pieza
3375	25302476	040.000.3259.00 Clozapina	Pieza
3376	25302477	040.000.3259.01 Clozapina	Pieza
3377	25302478	010.000.3999.00 Colagena-Polivinilpirrolidona	Pieza
3378	25302479	010.000.3999.01 Colagena-Polivinilpirrolidona	Pieza
3379	25302480	010.000.5865.00 Colistimetato	Pieza
3380	25302481	010.000.6053.00 Complejo de protombina humana	Pieza
3381	25302482	010.000.4248.00 Concentrado de proteinas humanas coagulables	Pieza
3382	25302483	010.000.4285.00 Concentrado de proteinas humanas coagulables	Pieza
3383	25302484	010.000.4279.00 Concentrado de proteinas humanas coagulables	Pieza
3384	25302485	010.000.4282.00 Concentrado de proteinas humanas coagulables	Pieza
3385	25302486	010.000.4283.00 Concentrado de proteinas humanas coagulables	Pieza
3386	25302487	010.000.4284.00 Concentrado de proteinas humanas coagulables	Pieza
3387	25302488	010.000.6032.00 Concentrado de proteinas humanas coagulables	Pieza
3388	25302489	010.000.6033.00 Concentrado de proteinas humanas coagulables	Pieza
3389	25302490	010.000.6031.00 Concentrado de proteinas humanas coagulables	Pieza
3390	25302491	010.000.4286.00 Concentrado de proteinas humanas coagulables	Pieza
3391	25302492	010.000.4287.00 Concentrado de proteinas humanas coagulables	Pieza
3392	25302493	010.000.4288.00 Concentrado de proteinas humanas coagulables	Pieza
3393	25302494	010.000.5770.00 Crizotinib	Pieza
3394	25302495	010.000.5771.00 Crizotinib	Pieza
3395	25302496	010.000.5377.00 Cromo	Pieza
3396	25302497	010.000.5377.01 Cromo	Pieza
3397	25302498	010.000.6044.00 Daclatasvir	Pieza
3398	25302499	010.000.5085.00 Daclizumab	Pieza
3399	25302500	010.000.5085.01 Daclizumab	Pieza
3400	25302501	010.000.6007.00 Dapagliflozina	Pieza
3401	25302502	010.000.6007.01 Dapagliflozina	Pieza
3402	25302503	010.000.5862.00 Darunavir	Pieza
3403	25302504	010.000.5860.00 Darunavir	Pieza
3404	25302505	010.000.4289.00 Darunavir	Pieza
3405	25302506	010.000.5861.00 Darunavir	Pieza
3406	25302507	010.000.4323.00 Dasatinib	Pieza
3407	25302508	030.000.5234.01 D-Biotina	Pieza
3408	25302509	030.000.5234.00 D-Biotina	Pieza
3409	25302510	010.000.5970.00 Degarelix	Pieza
3410	25302511	010.000.5970.01 Degarelix	Pieza
3411	25302512	010.000.5971.00 Degarelix	Pieza
3412	25302513	010.000.5971.01 Degarelix	Pieza
3413	25302514	010.000.6013.00 Denosumab	Pieza
3414	25302515	010.000.5613.00 Denosumab	Pieza
3415	25302516	010.000.5691.00 Desmopresina	Pieza
3416	25302517	010.000.5690.00 Desmopresina	Pieza
3417	25302518	010.000.5635.00 Dexlansoprazol	Pieza
3418	25302519	010.000.5635.01 Dexlansoprazol	Pieza
3419	25302520	010.000.0247.00 Dexmedetomidina	Pieza
3420	25302521	010.000.0247.02 Dexmedetomidina	Pieza
3421	25302522	010.000.0247.01 Dexmedetomidina	Pieza
3422	25302523	010.000.4408.01 Diclofenaco	Pieza
3423	25302524	010.000.4408.00 Diclofenaco	Pieza
3424	25302525	010.000.6001.00 Dienogest	Pieza
3425	25302526	010.000.2736.01 Dieta elemental	Pieza
3426	25302527	010.000.2736.00 Dieta elemental	Pieza
3427	25302528	010.000.5391.00 Dieta polimerica sin fibra	Pieza
3428	25302529	010.000.6048.00 Dimetilfumarato	Pieza
3429	25302530	010.000.6081.00 Dimetilfumarato	Pieza
3430	25302531	010.000.4208.00 Dinoprostona	Pieza
3431	25302532	010.000.4208.01 Dinoprostona	Pieza
3432	25302533	010.000.0642.00 Dipiridamol	Pieza
3433	25302534	010.000.0642.03 Dipiridamol	Pieza
3434	25302535	010.000.0642.01 Dipiridamol	Pieza
3435	25302536	010.000.0642.02 Dipiridamol	Pieza
3436	25302537	010.000.5457.01 Docetaxel	Pieza
3437	25302538	010.000.5457.02 Docetaxel	Pieza
3438	25302539	010.000.5437.01 Docetaxel	Pieza
3439	25302540	010.000.5437.02 Docetaxel	Pieza
3440	25302541	010.000.4365.00 Donepecilo	Pieza
3441	25302542	010.000.4365.01 Donepecilo	Pieza
3442	25302543	010.000.4364.00 Donepecilo	Pieza
3443	25302544	010.000.4364.01 Donepecilo	Pieza
3444	25302545	010.000.4485.00 Duloxetina	Pieza
3445	25302546	010.000.5319.00 Dutasterida	Pieza
3446	25302547	010.000.5319.01 Dutasterida	Pieza
3447	25302548	010.000.5640.00 Efavirenz, emtricitabina, tenofovir fumarato de disoproxilo	Pieza
3448	25302549	010.000.3623.00 Electrolitos orales	Pieza
3449	25302550	010.000.6073.00 Elosulfasa alfa	Pieza
3450	25302551	010.000.5636.00 Eltrombopag	Pieza
3451	25302552	010.000.5637.00 Eltrombopag	Pieza
3452	25302553	010.000.6008.00 Empagliflozina	Pieza
3453	25302554	010.000.6009.00 Empagliflozina	Pieza
3454	25302555	010.000.6079.00 Empagliflozina/metformina	Pieza
3455	25302556	010.000.6077.00 Empagliflozina/metformina	Pieza
3456	25302557	010.000.6078.00 Empagliflozina/metformina	Pieza
3457	25302558	010.000.4269.01 Enfuvirtida	Pieza
3458	25302559	010.000.5931.00 Enoxaparina Sodica	Pieza
3459	25302560	010.000.4242.01 Enoxaparina	Pieza
3460	25302561	010.000.2154.01 Enoxaparina	Pieza
3461	25302562	010.000.4224.01 Enoxaparina	Pieza
3462	25302563	010.000.1773.00 Epirubicina	Pieza
3463	25302564	010.000.1774.00 Epirubicina	Pieza
3464	25302565	010.000.4245.01 Eptacog alfa (Factor de coagulacion VII alfa recombinante)	Pieza
3465	25302566	010.000.4245.00 Eptacog alfa (Factor de coagulacion VII alfa recombinante)	Pieza
3466	25302567	010.000.4250.00 Eptacog alfa (Factor de coagulacion VII alfa recombinante)	Pieza
3467	25303349	Bedaquiline	Pieza
3468	25302568	010.000.4250.01 Eptacog alfa (Factor de coagulacion VII alfa recombinante)	Pieza
3469	25302569	010.000.4238.01 Eptacog alfa (Factor de coagulacion VII alfa recombinante)	Pieza
3470	25302570	010.000.4238.00 Eptacog alfa (Factor de coagulacion VII alfa recombinante)	Pieza
3471	25302571	010.000.5338.01 Eritropoyetina	Pieza
3472	25302572	010.000.5338.00 Eritropoyetina	Pieza
3473	25302573	010.000.5333.00 Eritropoyetina	Pieza
3474	25302574	010.000.5333.01 Eritropoyetina	Pieza
3475	25302575	010.000.5333.02 Eritropoyetina	Pieza
3476	25302577	010.000.5339.01 Eritropoyetina	Pieza
3477	25302578	010.000.5474.00 Erlotinib	Pieza
3478	25302579	010.000.4480.01 Escitalopram	Pieza
3479	25302580	010.000.4480.00 Escitalopram	Pieza
3480	25302581	010.000.2304.01 Espironolactona	Pieza
3481	25302582	010.000.4510.01 Etanercept	Pieza
3482	25302583	010.000.4510.00 Etanercept	Pieza
3483	25302584	010.000.4511.00 Etanercept	Pieza
3484	25302585	010.000.4511.01 Etanercept	Pieza
3485	25302586	010.000.4511.02 Etanercept	Pieza
3486	25302587	010.000.5275.00 Etravirina	Pieza
3487	25302588	010.000.6074.00 Etravirina	Pieza
3488	25302589	010.000.5652.00 Everolimus	Pieza
3489	25302590	010.000.5656.00 Everolimus	Pieza
3490	25302591	010.000.5651.00 Everolimus	Pieza
3491	25302592	010.000.5418.00 Exemestano	Pieza
3492	25302593	010.000.5418.01 Exemestano	Pieza
3493	25302594	010.000.5418.02 Exemestano	Pieza
3494	25302595	010.000.6054.00 Exenatida	Pieza
3495	25302596	010.000.4169.00 Exenatida	Pieza
3496	25302597	010.000.4169.01 Exenatida	Pieza
3497	25302598	010.000.4024.01 Ezetimiba	Pieza
3498	25302599	010.000.4024.02 Ezetimiba	Pieza
3499	25302600	010.000.4024.03 Ezetimiba	Pieza
3500	25302601	010.000.4024.04 Ezetimiba	Pieza
3501	25302602	010.000.4024.05 Ezetimiba	Pieza
3502	25302603	010.000.4024.00 Ezetimiba	Pieza
3503	25302604	010.000.4025.01 Ezetimiba-Simvastatina	Pieza
3504	25302605	010.000.4025.00 Ezetimiba-Simvastatina	Pieza
3505	25302606	010.000.5344.01 Factor IX	Pieza
3506	25302607	010.000.5343.01 Factor IX	Pieza
3507	25302608	010.000.5638.00 Factor VIII antihemofilico humano, factor de Von Willebrand	Pieza
3508	25302609	010.000.5639.00 Factor VIII antihemofilico humano, factor de Von Willebrand	Pieza
3509	25302610	010.000.6059.00 Factor VIII antihemofilico, factor de Von Willebrand	Pieza
3510	25302611	010.000.6058.00 Factor VIII antihemofilico, factor de Von Willebrand	Pieza
3511	25302612	010.000.4324.00 Factor VIII de la coagulacion humano	Pieza
3512	25302613	010.000.5643.00 Factor VIII de la coagulacion sanguinea humano/factor de Von Willebrand	Pieza
3513	25302614	010.000.5644.00 Factor VIII de la coagulacion sanguinea humano/factor de Von Willebrand	Pieza
3514	25302615	010.000.6070.00 Fibrinogeno humano	Pieza
3515	25302616	010.000.0626.00 Fitomenadiona	Pieza
3516	25302617	010.000.0626.01 Fitomenadiona	Pieza
3517	25302618	010.000.1732.00 Fitomenadiona	Pieza
3518	25302619	010.000.1732.01 Fitomenadiona	Pieza
3519	25302620	040.000.0206.00 Flunitrazepam	Pieza
3520	25302621	040.000.0206.01 Flunitrazepam	Pieza
3521	25302622	010.000.0903.00 Fluorouracilo	Pieza
3522	25302623	010.000.4483.01 Fluoxetina	Pieza
3523	25302624	010.000.4483.00 Fluoxetina	Pieza
3524	25302625	010.000.3263.00 Flupentixol	Pieza
3525	25302626	010.000.3263.01 Flupentixol	Pieza
3526	25302627	010.000.3263.02 Flupentixol	Pieza
3527	25302628	010.000.5646.00 Fluticasona	Pieza
3528	25302629	010.000.5980.00 Fluticasona, vilanterol	Pieza
3529	25302630	010.000.4244.01 Fluvastatina	Pieza
3530	25302631	010.000.4244.00 Fluvastatina	Pieza
3531	25302632	010.000.4144.01 Folitropina alfa o folitropina beta	Pieza
3532	25302633	010.000.4144.00 Folitropina alfa o folitropina beta	Pieza
3533	25302634	010.000.5206.01 Folitropina beta o folitropina alfa	Pieza
3534	25302635	010.000.5206.00 Folitropina beta o folitropina alfa	Pieza
3535	25302636	010.000.4143.00 Folitropina beta	Pieza
3536	25302637	010.000.4142.00 Folitropina beta	Pieza
3537	25302638	030.000.0013.00 Formula de proteina extensamente hidrolizada	Pieza
3538	25302639	030.000.5394.00 Formula de proteina extensamente hidrolizada con trigliceridos de cadena media	Pieza
3539	25302640	030.000.5952.00 Formula de proteina hidrolizada de arroz etapa 1	Pieza
3540	25302641	030.000.5951.00 Formula de proteina hidrolizada de arroz etapa 2	Pieza
3541	25302642	010.000.5401.00 Formula de seguimiento libre de fenilalanina	Pieza
3542	25302643	010.000.6023.01 Fosaprepitant	Pieza
3543	25302644	010.000.6023.00 Fosaprepitant	Pieza
3544	25302645	010.000.5335.00 Fosfolipidos de pulmon porcino	Pieza
3545	25302646	010.000.5335.01 Fosfolipidos de pulmon porcino	Pieza
3546	25302647	010.000.4465.01 Galantamina	Pieza
3547	25302648	010.000.4465.02 Galantamina	Pieza
3548	25302649	010.000.4465.03 Galantamina	Pieza
3549	25302650	010.000.4465.00 Galantamina	Pieza
3550	25302651	010.000.4464.01 Galantamina	Pieza
3551	25302652	010.000.4464.02 Galantamina	Pieza
3552	25302653	010.000.4464.03 Galantamina	Pieza
3553	25302654	010.000.4464.00 Galantamina	Pieza
3554	25302655	010.000.5543.00 Galsulfasa	Pieza
3555	25302656	010.000.4281.00 Gentamicina colageno	Pieza
3556	25302657	010.000.4280.00 Gentamicina colageno	Pieza
3557	25302658	010.000.4280.01 Gentamicina colageno	Pieza
3558	25302659	010.000.4281.01 Gentamicina colageno	Pieza
3559	25302660	010.000.6057.00 Gestodeno / etinilestradiol	Pieza
3560	25302661	010.000.3620.01 Gluconato de calcio	Pieza
3561	25302662	010.000.3620.00 Gluconato de calcio	Pieza
3562	25302663	010.000.3601.00 Glucosa	Pieza
3563	25302664	010.000.5950.00 Golomumab	Pieza
3564	25302665	010.000.1081.00 Gonadotrofina corionica	Pieza
3565	25302666	010.000.1081.01 Gonadotrofina corionica	Pieza
3566	25302667	010.000.1081.02 Gonadotrofina corionica	Pieza
3567	25302668	010.000.4155.00 Gonadotrofinas postmenopausicas humanas	Pieza
3568	25302669	010.000.4155.01 Gonadotrofinas postmenopausicas humanas	Pieza
3569	25302670	040.000.4481.00 Haloperidol	Pieza
3570	25302671	040.000.4481.01 Haloperidol	Pieza
3571	25302672	040.000.4477.00 Haloperidol	Pieza
3572	25302673	020.000.6060.00 Hemaglutininas recombinantes para la cepa viral de influenza H1N1, H3N2 Y B	Pieza
3573	25302674	010.000.6019.00 Hialuronato de sodio	Pieza
3574	25302675	010.000.5491.00 Hidralazina, valproato de magnesio Hidralazina, valproato de magnesio	Pieza
3575	25302676	010.000.5492.00 Hidralazina, valproato de magnesio Hidralazina, valproato de magnesio	Pieza
3576	25302677	010.000.4134.01 Hidroquinona	Pieza
3577	25302678	010.000.4134.00 Hidroquinona	Pieza
3578	25302679	010.000.1713.01 Hierro aminoquelado y acido folico	Pieza
3579	25302680	010.000.1713.02 Hierro aminoquelado y acido folico	Pieza
3580	25302681	010.000.1713.00 Hierro aminoquelado y acido folico	Pieza
3581	25302682	010.000.6042.01 Ibrutinib	Pieza
3582	25302683	010.000.6042.00 Ibrutinib	Pieza
3583	25302684	010.000.6076.00 Ibuprofeno	Pieza
3584	25302685	010.000.5943.00 Ibuprofeno	Pieza
3585	25302686	010.000.5944.00 Ibuprofeno	Pieza
3586	25302687	010.000.5940.00 Ibuprofeno	Pieza
3587	25302688	010.000.5940.01 Ibuprofeno	Pieza
3588	25302689	010.000.5940.02 Ibuprofeno	Pieza
3589	25302690	010.000.5940.03 Ibuprofeno	Pieza
3590	25302691	010.000.5941.00 Ibuprofeno	Pieza
3591	25302692	010.000.5941.01 Ibuprofeno	Pieza
3592	25302693	010.000.5941.02 Ibuprofeno	Pieza
3593	25302694	010.000.5941.03 Ibuprofeno	Pieza
3594	25302695	010.000.5941.04 Ibuprofeno	Pieza
3595	25302696	010.000.5942.00 Ibuprofeno	Pieza
3596	25302697	010.000.5942.01 Ibuprofeno	Pieza
3597	25302698	010.000.5942.02 Ibuprofeno	Pieza
3598	25302699	010.000.5942.03 Ibuprofeno	Pieza
3599	25302700	010.000.5942.04 Ibuprofeno	Pieza
3600	25302701	010.000.5990.00 Icatibant	Pieza
3601	25302702	010.000.4434.00 Idarubicina	Pieza
3602	25302703	010.000.2826.00 Idoxuridina	Pieza
3603	25302704	010.000.2826.01 Idoxuridina	Pieza
3604	25302705	010.000.5550.00 Idursulfasa	Pieza
3605	25302706	010.000.5848.00 Iloprost	Pieza
3606	25302707	010.000.5545.00 Imiglucerasa	Pieza
3607	25302708	010.000.5287.01 Imipenem y cilastatina	Pieza
3608	25302709	010.000.5287.00 Imipenem y cilastatina	Pieza
3609	25302710	010.000.5265.01 Imipenem y cilastatina	Pieza
3610	25302711	010.000.5265.00 Imipenem y cilastatina	Pieza
3611	25302712	010.000.5840.00 Indacaterol	Pieza
3612	25302713	010.000.5841.00 Indacaterol	Pieza
3613	25302714	010.000.6021.00 Indacaterol/ Glicopirronio	Pieza
3614	25302715	010.000.3412.01 Indometacina	Pieza
3615	25302716	010.000.3412.00 Indometacina	Pieza
3616	25302717	010.000.6055.00 Inhibidor de la esterasa C1 humano	Pieza
3617	25302718	020.000.2528.00 Inmunoglobulina antihepatitis B	Pieza
3618	25302719	020.000.2528.01 Inmunoglobulina antihepatitis B	Pieza
3619	25302720	010.000.4234.00 Inmunoglobulina antilinfocitos T humanos	Pieza
3620	25302721	010.000.5244.00 Inmunoglobulina G no modificada	Pieza
3621	25302722	010.000.5244.01 Inmunoglobulina G no modificada	Pieza
3622	25302723	010.000.5240.01 Inmunoglobulina G no modificada	Pieza
3623	25302724	010.000.5240.00 Inmunoglobulina G no modificada	Pieza
3624	25302725	020.000.3833.01 Inmunoglobulina humana antirrabica	Pieza
3625	25302726	020.000.3833.02 Inmunoglobulina humana antirrabica	Pieza
3626	25302727	020.000.3831.01 Inmunoglobulina humana hiperinmune antitetanica	Pieza
3627	25302728	020.000.3831.02 Inmunoglobulina humana hiperinmune antitetanica	Pieza
3628	25302729	010.000.6025.00 Inmunoglobulina humana normal subcutanea	Pieza
3629	25302730	010.000.5641.00 Inmunoglobulina humana normal subcutanea	Pieza
3630	25302731	010.000.6026.00 Inmunoglobulina humana normal subcutanea	Pieza
3631	25302732	010.000.5642.00 Inmunoglobulina humana normal subcutanea	Pieza
3632	25302733	010.000.6027.00 Inmunoglobulina humana normal subcutanea	Pieza
3633	25302734	010.000.5698.00 Inmunoglobulina humana	Pieza
3634	25302735	010.000.5696.00 Inmunoglobulina humana	Pieza
3635	25302736	010.000.5697.00 Inmunoglobulina humana	Pieza
3636	25302737	010.000.4165.00 Insulina detemir	Pieza
3637	25302738	010.000.4165.01 Insulina detemir	Pieza
3638	25302739	010.000.4158.01 Insulina glargina	Pieza
3639	25302740	010.000.4158.00 Insulina glargina	Pieza
3640	25302741	010.000.1050.01 Insulina humana accion intermedia NPH	Pieza
3641	25302742	010.000.1050.00 Insulina humana accion intermedia NPH	Pieza
3642	25302743	010.000.1051.01 Insulina humana accion rapida regular	Pieza
3643	25302744	010.000.1051.00 Insulina humana accion rapida regular	Pieza
3644	25302745	010.000.4148.01 Insulina lispro lispro protamina	Pieza
3645	25302746	010.000.5237.01 Interferon (beta)	Pieza
3646	25302747	010.000.5237.03 Interferon (beta)	Pieza
3647	25302748	010.000.5237.02 Interferon (beta)	Pieza
3648	25302749	010.000.5237.00 Interferon (beta)	Pieza
3649	25302750	010.000.5254.01 Interferon (beta)	Pieza
3650	25302751	010.000.5254.00 Interferon (beta)	Pieza
3651	25302752	010.000.5250.02 Interferon (beta)	Pieza
3652	25302753	010.000.5250.01 Interferon (beta)	Pieza
3653	25302754	010.000.5250.00 Interferon (beta)	Pieza
3654	25302755	010.000.6016.00 Ipilimumab	Pieza
3655	25302756	010.000.2190.01 Ipratropio - Salbutamol	Pieza
3656	25302757	010.000.2162.01 Ipratropio	Pieza
3657	25302758	010.000.5801.00 Irbesartan, Amlodipino	Pieza
3658	25302759	010.000.5802.00 Irbesartan, Amlodipino	Pieza
3659	25302760	010.000.4118.01 Isosorbida dinitrato de	Pieza
3660	25302761	010.000.6071.00 Ivabradina	Pieza
3661	25302762	010.000.6072.00 Ivabradina	Pieza
3662	25302763	010.000.3422.00 Ketorolaco	Pieza
3663	25302764	010.000.5664.00 Lacosamida	Pieza
3664	25302765	010.000.5661.00 Lacosamida	Pieza
3665	25302766	010.000.5662.00 Lacosamida	Pieza
3666	25302767	010.000.5663.00 Lacosamida	Pieza
3667	25302768	010.000.5660.00 Lacosamida	Pieza
3668	25302769	010.000.5282.01 Lamivudina	Pieza
3669	25302770	010.000.5282.00 Lamivudina	Pieza
3670	25302771	010.000.5421.00 Lapatinib	Pieza
3671	25302772	010.000.4229.00 L-asparginasa	Pieza
3672	25302773	010.000.4229.01 L-asparginasa	Pieza
3673	25302774	010.000.4411.00 Latanoprost	Pieza
3674	25302775	010.000.4411.01 Latanoprost	Pieza
3675	25302776	010.000.5450.00 Leuprorelina	Pieza
3676	25302777	010.000.5972.00 Leuprorelina	Pieza
3677	25302778	010.000.3055.01 Leuprorelina	Pieza
3678	25302779	010.000.3055.00 Leuprorelina	Pieza
3679	25302780	010.000.2169.01 Levocarnitina	Pieza
3680	25302781	010.000.2169.00 Levocarnitina	Pieza
3681	25302782	010.000.2169.02 Levocarnitina	Pieza
3682	25302783	040.000.2654.00 Levodopa y carbidopa	Pieza
3683	25302784	040.000.2657.01 Levodopa y carbidopa	Pieza
3684	25302785	040.000.2657.00 Levodopa y carbidopa	Pieza
3685	25302786	010.000.6075.00 Levonorgestrel	Pieza
3686	25302787	010.000.5097.01 Levosimendan	Pieza
3687	25302788	010.000.5097.00 Levosimendan	Pieza
3688	25302789	010.000.0260.00 Lidocaina	Pieza
3689	25302790	010.000.0260.01 Lidocaina	Pieza
3690	25302791	010.000.0260.02 Lidocaina	Pieza
3691	25302792	010.000.0267.00 Lidocaina, epinefrina	Pieza
3692	25302793	010.000.5382.00 Lipidos intravenosos	Pieza
3693	25302794	010.000.2745.01 Lipidos intravenosos: Aceite de pescado (acidos grasos)	Pieza
3694	25302795	010.000.2745.00 Lipidos intravenosos: Aceite de pescado (acidos grasos)	Pieza
3695	25302796	010.000.5744.00 Lixisenatida	Pieza
3696	25302797	010.000.5745.00 Lixisenatida	Pieza
3697	25302798	010.000.5286.00 Lopinavir-Ritonavir	Pieza
3698	25302799	010.000.3830.00 L-ornitina-L-aspartato	Pieza
3699	25302800	010.000.3830.01 L-ornitina-L-aspartato	Pieza
3700	25302801	010.000.4145.00 Lutropina alfa	Pieza
3701	25302802	010.000.4145.02 Lutropina alfa	Pieza
3702	25302803	010.000.4145.01 Lutropina alfa	Pieza
3703	25302804	010.000.6022.00 Macitentan	Pieza
3704	25302805	010.000.5324.00 Maraviroc	Pieza
3705	25302806	010.000.5325.00 Maraviroc	Pieza
3706	25302807	010.000.1761.01 Mercaptopurina	Pieza
3707	25302808	010.000.5292.00 Meropenem	Pieza
3708	25302809	010.000.5292.01 Meropenem	Pieza
3709	25302810	010.000.5291.00 Meropenem	Pieza
3710	25302811	010.000.5291.01 Meropenem	Pieza
3711	25302812	010.000.4186.04 Mesalazina	Pieza
3712	25302813	010.000.4186.00 Mesalazina	Pieza
3713	25302814	010.000.4186.01 Mesalazina	Pieza
3714	25302815	010.000.4186.02 Mesalazina	Pieza
3715	25302816	010.000.4186.03 Mesalazina	Pieza
3716	25302817	010.000.4175.00 Mesalazina	Pieza
3717	25302818	010.000.4175.01 Mesalazina	Pieza
3718	25302819	010.000.6082.00 Mesilato de eribulina	Pieza
3719	25302820	040.000.5910.00 Metadona	Pieza
3720	25302821	040.000.4470.00 Metilfenidato	Pieza
3721	25302822	040.000.4470.01 Metilfenidato	Pieza
3722	25302823	040.000.4471.00 Metilfenidato	Pieza
3723	25302824	040.000.4471.01 Metilfenidato	Pieza
3724	25302825	040.000.4472.00 Metilfenidato	Pieza
3725	25302826	040.000.4472.01 Metilfenidato	Pieza
3726	25302827	010.000.5360.00 Metoxi-polietilenglicol eritropoyetina beta	Pieza
3727	25302828	010.000.5361.00 Metoxi-polietilenglicol eritropoyetina beta	Pieza
3728	25302829	010.000.1308.00 Metronidazol	Pieza
3729	25302830	010.000.1308.01 Metronidazol	Pieza
3730	25302831	010.000.5650.00 Mifamurtida	Pieza
3731	25302832	010.000.6034.00 Mifepristona	Pieza
3732	25302833	010.000.5100.01 Milrinona	Pieza
3733	25302834	010.000.4139.01 Minociclina	Pieza
3734	25302835	010.000.4139.00 Minociclina	Pieza
3735	25302836	010.000.6011.00 Misoprostol	Pieza
3736	25302837	010.000.6012.00 Misoprostol	Pieza
3737	25302838	010.000.6012.04 Misoprostol	Pieza
3738	25302839	010.000.6012.01 Misoprostol	Pieza
3739	25302840	010.000.6012.02 Misoprostol	Pieza
3740	25302841	010.000.6012.03 Misoprostol	Pieza
3741	25302842	010.000.5429.00 Molgramostim	Pieza
3742	25302843	010.000.4133.00 Mometasona	Pieza
3743	25302844	010.000.4133.01 Mometasona	Pieza
3744	25302845	010.000.4335.00 Montelukast	Pieza
3745	25302846	010.000.4335.01 Montelukast	Pieza
3746	25302847	010.000.4335.02 Montelukast	Pieza
3747	25302848	040.000.2105.00 Morfina	Pieza
3748	25302849	040.000.2105.01 Morfina	Pieza
3749	25302850	040.000.2105.02 Morfina	Pieza
3750	25302851	040.000.2104.00 Morfina	Pieza
3751	25302852	040.000.2104.01 Morfina	Pieza
3752	25302853	040.000.2104.02 Morfina	Pieza
3753	25302854	010.000.6014.00 Moroctocog Alfa	Pieza
3754	25302855	010.000.6015.00 Moroctocog Alfa	Pieza
3755	25302856	010.000.5760.00 Moroctocog Alfa	Pieza
3756	25302857	010.000.5761.00 Moroctocog Alfa	Pieza
3757	25302858	010.000.5384.00 Multivitaminas	Pieza
3758	25302859	010.000.5385.00 Multivitaminas	Pieza
3759	25302860	010.000.5385.02 Multivitaminas	Pieza
3760	25302861	010.000.5385.01 Multivitaminas	Pieza
3761	25302862	010.000.2155.01 Nadroparina	Pieza
3762	25302863	010.000.2155.00 Nadroparina	Pieza
3763	25302864	010.000.4223.01 Nadroparina	Pieza
3764	25302865	010.000.4222.01 Nadroparina	Pieza
3765	25302866	040.000.0132.00 Nalbufina	Pieza
3766	25302867	040.000.0132.01 Nalbufina	Pieza
3767	25302868	010.000.5296.01 Nevirapina	Pieza
3768	25302869	010.000.5296.00 Nevirapina	Pieza
3769	25302870	010.000.4322.01 Nilotinib	Pieza
3770	25302871	010.000.6067.00 Nintedanib	Pieza
3771	25302872	010.000.6068.00 Nintedanib	Pieza
3772	25302873	010.000.2523.01 Nitazoxanida	Pieza
3773	25302874	010.000.2523.02 Nitazoxanida	Pieza
3774	25302875	010.000.2523.00 Nitazoxanida	Pieza
3775	25302876	010.000.2524.02 Nitazoxanida	Pieza
3776	25302877	010.000.2524.00 Nitazoxanida	Pieza
3777	25302878	010.000.2524.01 Nitazoxanida	Pieza
3778	25302879	010.000.5832.00 Nitisinona	Pieza
3779	25302880	010.000.5830.00 Nitisinona	Pieza
3780	25302881	010.000.5831.00 Nitisinona	Pieza
3781	25302882	010.000.5388.00 Nutricion parentera	Pieza
3782	25302883	010.000.5389.00 Nutricion parentera	Pieza
3783	25302884	010.000.2730.01 Nutricion parentera	Pieza
3784	25302885	010.000.2730.02 Nutricion parentera	Pieza
3785	25302886	010.000.2730.03 Nutricion parentera	Pieza
3786	25302887	010.000.5850.00 Octocog alfa (Factor VIII de la coagulacion sanguinea humana recombinante ADNr)	Pieza
3787	25302888	010.000.5851.00 Octocog alfa (Factor VIII de la coagulacion sanguinea humana recombinante ADNr)	Pieza
3788	25302891	010.000.5171.00 Octreotida	Pieza
3789	25302892	010.000.5171.01 Octreotida	Pieza
3790	25302893	010.000.4261.01 Ofloxacina	Pieza
3791	25302894	010.000.4261.02 Ofloxacina	Pieza
3792	25302895	010.000.4261.00 Ofloxacina	Pieza
3793	25302896	010.000.5486.00 Olanzapina	Pieza
3794	25302897	010.000.5486.01 Olanzapina	Pieza
3795	25302898	010.000.5485.00 Olanzapina	Pieza
3796	25302899	010.000.5485.01 Olanzapina	Pieza
3797	25302900	010.000.6041.00 Ombitasvir, paritaprevir, ritonavir y dasabuvir	Pieza
3798	25302901	010.000.5187.00 Omeprazol o Pantoprazol	Pieza
3799	25302902	010.000.4584.00 Oseltamivir	Pieza
3800	25302903	010.000.4583.00 Oseltamivir	Pieza
3801	25302904	010.000.4585.00 Oseltamivir	Pieza
3802	25302905	010.000.4305.00 Oxibutinina	Pieza
3803	25302906	010.000.4305.01 Oxibutinina	Pieza
3804	25302907	040.000.4033.01 Oxicodona	Pieza
3805	25302908	040.000.4033.00 Oxicodona	Pieza
3806	25302909	040.000.4032.01 Oxicodona	Pieza
3807	25302910	040.000.4032.00 Oxicodona	Pieza
3808	25302911	040.000.6040.00 Oxicodona	Pieza
3809	25302912	040.000.5711.00 Paliperidona	Pieza
3810	25302913	040.000.5710.00 Paliperidona	Pieza
3811	25302914	040.000.5713.00 Paliperidona	Pieza
3812	25302915	040.000.5712.00 Paliperidona	Pieza
3813	25302916	010.000.4321.01 Palivizumab	Pieza
3814	25302917	010.000.4320.01 Palivizumab	Pieza
3815	25302918	010.000.4188.00 Pancreatina	Pieza
3816	25302919	010.000.4188.01 Pancreatina	Pieza
3817	25302920	010.000.5653.00 Panitumumab	Pieza
3818	25302921	010.000.5186.01 Pantoprazol o Rabeprazol u Omeprazol	Pieza
3819	25302922	010.000.5186.02 Pantoprazol o Rabeprazol u Omeprazol	Pieza
3820	25302923	010.000.5186.00 Pantoprazol o Rabeprazol u Omeprazol	Pieza
3821	25302924	010.000.0514.02 Paracetamol	Pieza
3822	25302925	010.000.0514.00 Paracetamol	Pieza
3823	25302926	010.000.0514.01 Paracetamol	Pieza
3824	25302927	010.000.5721.01 Paracetamol	Pieza
3825	25302928	010.000.5721.00 Paracetamol	Pieza
3826	25302929	010.000.5720.01 Paracetamol	Pieza
3827	25302930	010.000.5720.00 Paracetamol	Pieza
3828	25302931	010.000.1101.00 Paricalcitol	Pieza
3829	25302932	010.000.1102.00 Paricalcitol	Pieza
3830	25302933	010.000.5654.00 Pazopanib	Pieza
3831	25302934	010.000.5223.00 Peginterferon alfa 2a	Pieza
3832	25302935	010.000.5223.01 Peginterferon alfa 2a	Pieza
3833	25302936	010.000.5223.02 Peginterferon alfa 2a	Pieza
3834	25302937	010.000.4122.00 Pentoxifilina	Pieza
3835	25302938	010.000.4122.01 Pentoxifilina	Pieza
3836	25302939	010.000.0865.00 Permetrina	Pieza
3837	25302940	010.000.6024.00 Pertuzumab	Pieza
3838	25302941	010.000.4131.01 Pimecrolimus	Pieza
3839	25302942	010.000.4131.00 Pimecrolimus	Pieza
3840	25302943	010.000.1210.00 Pinaverio	Pieza
3841	25302944	010.000.1210.01 Pinaverio	Pieza
3842	25302945	010.000.6069.00 Pirfenidona	Pieza
3843	25302946	010.000.5307.00 Plerixafor	Pieza
3844	25302947	010.000.6028.00 Pralatrexato	Pieza
3845	25302948	010.000.5603.00 Prasugrel	Pieza
3846	25302949	010.000.5603.01 Prasugrel	Pieza
3847	25302950	010.000.5602.00 Prasugrel	Pieza
3848	25302951	010.000.5602.01 Prasugrel	Pieza
3849	25302952	010.000.2186.01 Prednisolona - sulfacetamida	Pieza
3850	25302953	010.000.2186.00 Prednisolona - sulfacetamida	Pieza
3851	25302954	010.000.4358.00 Pregabalina	Pieza
3852	25302955	010.000.4358.01 Pregabalina	Pieza
3853	25302956	010.000.4356.00 Pregabalina	Pieza
3854	25302957	010.000.4356.01 Pregabalina	Pieza
3855	25302958	010.000.4058.00 Prilocaina, felipresina	Pieza
3856	25302959	010.000.4058.01 Prilocaina, felipresina	Pieza
3857	25302962	010.000.5494.00 Quetiapina	Pieza
3858	25302963	010.000.4163.00 Raloxifeno	Pieza
3859	25302964	010.000.4163.01 Raloxifeno	Pieza
3860	25302965	010.000.5236.00 Ranibizumab	Pieza
3861	25302966	010.000.1234.00 Ranitidina	Pieza
3862	25302967	010.000.1234.01 Ranitidina	Pieza
3863	25302968	010.000.5665.00 Rasagilina	Pieza
3864	25302969	010.000.5920.00 Ribavirina	Pieza
3865	25302970	010.000.2409.01 Rifampicina	Pieza
3866	25302971	010.000.5671.00 Rifaximina	Pieza
3867	25302972	010.000.5281.00 Ritonavir	Pieza
3868	25302973	010.000.5281.01 Ritonavir	Pieza
3869	25302974	010.000.5433.00 Rituximab	Pieza
3870	25302975	010.000.5433.01 Rituximab	Pieza
3871	25302976	010.000.5445.01 Rituximab	Pieza
3872	25302977	010.000.5445.00 Rituximab	Pieza
3873	25302978	010.000.5544.00 Rivaroxaban	Pieza
3874	25302979	010.000.5735.01 Rivaroxaban	Pieza
3875	25302980	010.000.5737.00 Rivaroxaban	Pieza
3876	25302981	010.000.5736.01 Rivaroxaban	Pieza
3877	25302982	010.000.4380.00 Rivastigmina	Pieza
3878	25302983	010.000.4379.00 Rivastigmina	Pieza
3879	25302984	010.000.4360.00 Rizatriptan	Pieza
3880	25302985	010.000.4360.01 Rizatriptan	Pieza
3881	25302986	010.000.5624.00 Romiplostim	Pieza
3882	25302987	010.000.4150.00 Rosiglitazona	Pieza
3883	25302988	010.000.4150.01 Rosiglitazona	Pieza
3884	25302989	010.000.4023.00 Rosuvastatina	Pieza
3885	25302990	010.000.0447.00 Salmeterol, Fluticasona	Pieza
3886	25302991	010.000.5622.00 Saxagliptina	Pieza
3887	25302992	010.000.6080.00 Secukinumab	Pieza
3888	25302993	010.000.1270.01 Senosidos A-B	Pieza
3889	25302994	010.000.0233.00 Sevoflurano	Pieza
3890	25302995	010.000.4309.00 Sildenafil	Pieza
3891	25302996	010.000.4309.01 Sildenafil	Pieza
3892	25302997	010.000.5845.00 Sildenafil	Pieza
3893	25302998	010.000.4308.00 Sildenafil	Pieza
3894	25302999	010.000.4308.01 Sildenafil	Pieza
3895	25303000	010.000.6020.01 Simeprevir	Pieza
3896	25303001	010.000.6020.00 Simeprevir	Pieza
3897	25303002	010.000.4124.00 Simvastatina	Pieza
3898	25303003	010.000.4124.01 Simvastatina	Pieza
3899	25303004	010.000.4152.00 Sitagliptina	Pieza
3900	25303005	010.000.4152.01 Sitagliptina	Pieza
3901	25303006	010.000.4153.00 Sitagliptina	Pieza
3902	25303007	010.000.4153.01 Sitagliptina	Pieza
3903	25303008	010.000.5704.00 Sitagliptina, metformina	Pieza
3904	25303009	010.000.5705.00 Sitagliptina, metformina	Pieza
3905	25303010	010.000.5705.01 Sitagliptina, metformina	Pieza
3906	25303011	010.000.5703.00 Sitagliptina, metformina	Pieza
3907	25303012	010.000.5703.01 Sitagliptina, metformina	Pieza
3908	25303013	010.000.6045.00 Sofosbuvir	Pieza
3909	25303014	010.000.6052.00 Sofosbuvir, ledipasvir	Pieza
3910	25303015	010.000.2347.00 Solucion para dialisis peritoneal	Pieza
3911	25303016	010.000.2516.00 Solucion para dialisis peritoneal	Pieza
3912	25303017	010.000.5752.00 Somatropina	Pieza
3913	25303018	010.000.5694.00 Somatropina	Pieza
3914	25303019	010.000.5694.01 Somatropina	Pieza
3915	25303020	010.000.5167.01 Somatropina	Pieza
3916	25303021	010.000.5167.00 Somatropina	Pieza
3917	25303022	010.000.5750.00 Somatropina	Pieza
3918	25303023	010.000.5753.00 Somatropina	Pieza
3919	25303024	010.000.5173.00 Somatropina	Pieza
3920	25303025	010.000.5754.00 Somatropina	Pieza
3921	25303026	010.000.5751.00 Somatropina	Pieza
3922	25303027	010.000.5174.01 Somatropina	Pieza
3923	25303028	010.000.5174.02 Somatropina	Pieza
3924	25303029	010.000.5174.00 Somatropina	Pieza
3925	25303030	010.000.5084.01 Tacrolimus	Pieza
3926	25303031	010.000.5084.00 Tacrolimus	Pieza
3927	25303032	010.000.5082.01 Tacrolimus	Pieza
3928	25303033	010.000.5082.00 Tacrolimus	Pieza
3929	25303034	010.000.5083.01 Tacrolimus	Pieza
3930	25303035	010.000.5083.00 Tacrolimus	Pieza
3931	25303036	010.000.4312.00 Tadalafil	Pieza
3932	25303037	010.000.4312.02 Tadalafil	Pieza
3933	25303038	010.000.4312.01 Tadalafil	Pieza
3934	25303039	010.000.4312.03 Tadalafil	Pieza
3935	25303040	010.000.5614.00 Taliglucerasa alfa	Pieza
3936	25303041	010.000.5309.00 Tamsulosina	Pieza
3937	25303042	010.000.5309.01 Tamsulosina	Pieza
3938	25303043	010.000.5309.02 Tamsulosina	Pieza
3939	25303044	040.000.5916.00 Tapentadol	Pieza
3940	25303045	040.000.5915.00 Tapentadol	Pieza
3941	25303046	010.000.5446.01 Tegafur - Uracilo	Pieza
3942	25303047	010.000.5446.00 Tegafur - Uracilo	Pieza
3943	25303048	010.000.5463.01 Temozolomida	Pieza
3944	25303049	010.000.5463.02 Temozolomida	Pieza
3945	25303050	010.000.5463.00 Temozolomida	Pieza
3946	25303051	010.000.5465.02 Temozolomida	Pieza
3947	25303052	010.000.5465.01 Temozolomida	Pieza
3948	25303053	010.000.5465.00 Temozolomida	Pieza
3949	25303054	010.000.4277.00 Tenofovir Disoproxil Fumarato o Tenofovir	Pieza
3950	25303055	010.000.5890.00 Terbinafina	Pieza
3951	25303056	010.000.4174.00 Teriparatida	Pieza
3952	25303057	010.000.5191.01 Terlipresina	Pieza
3953	25303058	010.000.5191.02 Terlipresina	Pieza
3954	25303059	010.000.5164.01 Testosterona	Pieza
3955	25303060	010.000.5164.00 Testosterona	Pieza
3956	25303061	010.000.2207.00 Tibolona	Pieza
3957	25303062	010.000.2207.01 Tibolona	Pieza
3958	25303063	010.000.5730.00 Ticagrelor	Pieza
3959	25303064	010.000.5730.01 Ticagrelor	Pieza
3960	25303065	010.000.6002.00 Tinzaparina Sodica	Pieza
3961	25303066	010.000.6003.00 Tinzaparina Sodica	Pieza
3962	25303067	010.000.6004.00 Tinzaparina Sodica	Pieza
3963	25303068	010.000.4123.01 Tirofiban	Pieza
3964	25303069	010.000.5140.01 Tirotropina alfa	Pieza
3965	25303070	010.000.5895.00 Tobramicina	Pieza
3966	25303071	010.000.2189.01 Tobramicina	Pieza
3967	25303072	010.000.2189.00 Tobramicina	Pieza
3968	25303073	010.000.5337.00 Tobramicina	Pieza
3969	25303074	010.000.4304.00 Tolterodina	Pieza
3970	25303075	010.000.4304.01 Tolterodina	Pieza
3971	25303076	010.000.5363.01 Topiramato	Pieza
3972	25303077	010.000.5363.00 Topiramato	Pieza
3973	25303078	010.000.5365.01 Topiramato	Pieza
3974	25303079	010.000.5365.00 Topiramato	Pieza
3975	25303080	010.000.5666.00 Toxina botulinica tipo A	Pieza
3976	25303081	020.000.3810.01 Toxoides tetanico y difterico (Td)	Pieza
3977	25303082	020.000.3810.00 Toxoides tetanico y difterico (Td)	Pieza
3978	25303083	010.000.6017.00 Trastuzumab Emtansina	Pieza
3979	25303084	010.000.6018.00 Trastuzumab Emtansina	Pieza
3980	25303085	010.000.6046.00 Trastuzumab	Pieza
3981	25303086	040.000.3241.00 Trifluoperazina	Pieza
3982	25303087	040.000.3241.01 Trifluoperazina	Pieza
3983	25303088	010.000.6030.00 Triptorelina	Pieza
3984	25303089	010.000.6029.00 Triptorelina	Pieza
3985	25303090	010.000.4409.01 Tropicamida	Pieza
3986	25303091	010.000.4409.00 Tropicamida	Pieza
3987	25303092	010.000.5456.00 Tropisetron	Pieza
3988	25303093	010.000.5456.02 Tropisetron	Pieza
3989	25303094	010.000.5456.01 Tropisetron	Pieza
3990	25303095	010.000.6063.00 Turoctocog Alfa (Factor VIII de coagulacion humano de origen ADN recombinante)	Pieza
3991	25303096	010.000.6064.00 Turoctocog Alfa (Factor VIII de coagulacion humano de origen ADN recombinante)	Pieza
3992	25303097	010.000.6065.00 Turoctocog Alfa (Factor VIII de coagulacion humano de origen ADN recombinante)	Pieza
3993	25303098	010.000.6061.00 Turoctocog Alfa (Factor VIII de coagulacion humano de origen ADN recombinante)	Pieza
3994	25303099	010.000.6066.00 Turoctocog Alfa (Factor VIII de coagulacion humano de origen ADN recombinante)	Pieza
3995	25303100	010.000.6062.00 Turoctocog Alfa (Factor VIII de coagulacion humano de origen ADN recombinante)	Pieza
3996	25303101	010.000.5695.00 Ustekinumab	Pieza
3997	25303102	010.000.5695.01 Ustekinumab	Pieza
3998	25303103	020.000.2506.00 Vacuna Antihaemophilus Influenzae tipo b y DPT	Pieza
3999	25303104	020.000.2522.00 Vacuna acelular antipertussis, con toxoides difterico y tetanico adsorbidos, con vacuna antipoliomielitica inactivada y con vacuna conjugada de Haemophilus influenzae tipo b	Pieza
4000	25303105	020.000.2522.01 Vacuna acelular antipertussis, con toxoides difterico y tetanico adsorbidos, con vacuna antipoliomielitica inactivada y con vacuna conjugada de Haemophilus influenzae tipo b	Pieza
4001	25303106	020.000.3822.01 Vacuna antiinfluenza	Pieza
4002	25303107	020.000.3822.02 Vacuna antiinfluenza	Pieza
4003	25303108	020.000.3822.00 Vacuna antiinfluenza	Pieza
4004	25303109	020.000.0147.04 Vacuna antineumococcica conjugada con proteina D de Haemophilus influenzae no tipificable (NTHi)	Pieza
4005	25303110	020.000.0147.03 Vacuna antineumococcica conjugada con proteina D de Haemophilus influenzae no tipificable (NTHi)	Pieza
4006	25303111	020.000.0147.01 Vacuna antineumococcica conjugada con proteina D de Haemophilus influenzae no tipificable (NTHi)	Pieza
4007	25303112	020.000.0147.00 Vacuna antineumococcica conjugada con proteina D de Haemophilus influenzae no tipificable (NTHi)	Pieza
4008	25303113	020.000.0147.02 Vacuna antineumococcica conjugada con proteina D de Haemophilus influenzae no tipificable (NTHi)	Pieza
4009	25303114	020.000.0146.00 Vacuna antineumococcica	Pieza
4010	25303115	020.000.0146.01 Vacuna antineumococcica	Pieza
4011	25303116	020.000.0146.02 Vacuna antineumococcica	Pieza
4012	25303117	020.000.0145.00 Vacuna antineumococcica	Pieza
4013	25303118	020.000.0145.01 Vacuna antineumococcica	Pieza
4014	25303119	020.000.3802.00 Vacuna antipoliomielitica Oral Bivalente tipo Sabin	Pieza
4015	25303120	020.000.3802.01 Vacuna antipoliomielitica Oral Bivalente tipo Sabin	Pieza
4016	25303121	020.000.3817.00 Vacuna antirrabica	Pieza
4017	25303122	020.000.3817.01 Vacuna antirrabica	Pieza
4018	25303123	020.000.6056.01 Vacuna antivaricela atenuada	Pieza
4019	25303124	020.000.6056.00 Vacuna antivaricela atenuada	Pieza
4020	25303125	020.000.3801.01 Vacuna BCG	Pieza
4021	25303126	020.000.3801.00 Vacuna BCG	Pieza
4022	25303127	020.000.3816.02 Vacuna conjugada antihaemophilus influenzae tipo b	Pieza
4023	25303128	020.000.3816.01 Vacuna conjugada antihaemophilus influenzae tipo b	Pieza
4024	25303129	020.000.3816.00 Vacuna conjugada antihaemophilus influenzae tipo b	Pieza
4025	25303130	020.000.4173.00 Vacuna contra el virus del papiloma humano	Pieza
4026	25303131	020.000.4173.01 Vacuna contra el virus del papiloma humano	Pieza
4027	25303132	020.000.4173.02 Vacuna contra el virus del papiloma humano	Pieza
4028	25303133	020.000.4172.00 Vacuna contra el virus del papiloma humano	Pieza
4029	25303134	020.000.4172.01 Vacuna contra el virus del papiloma humano	Pieza
4030	25303135	020.000.3825.01 Vacuna contra la Hepatitis A	Pieza
4031	25303136	020.000.3825.05 Vacuna contra la Hepatitis A	Pieza
4032	25303137	020.000.3825.03 Vacuna contra la Hepatitis A	Pieza
4033	25303139	020.000.3825.00 Vacuna contra la Hepatitis A	Pieza
4034	25303141	020.000.3825.02 Vacuna contra la Hepatitis A	Pieza
4035	25303142	020.000.3825.06 Vacuna contra la Hepatitis A	Pieza
4036	25303143	020.000.0150.02 Vacuna contra rotavirus	Pieza
4037	25303350	Cicloserina	Pieza
4038	25303144	020.000.0150.03 Vacuna contra rotavirus	Pieza
4039	25303145	020.000.0150.04 Vacuna contra rotavirus	Pieza
4040	25303146	020.000.0150.05 Vacuna contra rotavirus	Pieza
4041	25303147	020.000.0150.00 Vacuna contra rotavirus	Pieza
4042	25303148	020.000.0150.01 Vacuna contra rotavirus	Pieza
4043	25303149	020.000.3808.02 Vacuna de refuerzo contra difteria, tetanos y tosferina acelular (Tdpa)	Pieza
4044	25303150	020.000.3808.00 Vacuna de refuerzo contra difteria, tetanos y tosferina acelular (Tdpa)	Pieza
4045	25303151	020.000.3808.04 Vacuna de refuerzo contra difteria, tetanos y tosferina acelular (Tdpa)	Pieza
4046	25303152	020.000.3808.01 Vacuna de refuerzo contra difteria, tetanos y tosferina acelular (Tdpa)	Pieza
4047	25303153	020.000.3808.03 Vacuna de refuerzo contra difteria, tetanos y tosferina acelular (Tdpa)	Pieza
4048	25303154	020.000.3800.00 Vacuna doble viral (SR) contra sarampion y rubeola	Pieza
4049	25303155	020.000.3823.00 Vacuna Pentavalente contra difteria, tos ferina, tetanos, hepatitis B, e infecciones invasivas por Haemophilus influenzae tipo b (DPT+HB+Hib)	Pieza
4050	25303156	020.000.0151.00 Vacuna Pentavalente contra rotavirus	Pieza
4051	25303157	020.000.2529.00 Vacuna recombinante contra la Hepatitis B	Pieza
4052	25303158	020.000.2529.01 Vacuna recombinante contra la Hepatitis B	Pieza
4053	25303159	010.000.4372.01 Valaciclovir	Pieza
4054	25303160	010.000.4372.00 Valaciclovir	Pieza
4055	25303161	010.000.4311.00 Vardenafil	Pieza
4056	25303162	010.000.4311.01 Vardenafil	Pieza
4057	25303163	010.000.4310.01 Vardenafil	Pieza
4058	25303164	010.000.4310.00 Vardenafil	Pieza
4059	25303165	010.000.5615.00 Velaglucerasa alfa	Pieza
4060	25303166	010.000.5620.00 Vildagliptina	Pieza
4061	25303167	010.000.5702.00 Vildagliptina, Metformina	Pieza
4062	25303168	010.000.5700.00 Vildagliptina, Metformina	Pieza
4063	25303169	010.000.5701.00 Vildagliptina, Metformina	Pieza
4064	25303170	020.000.3835.00 Vitamina A	Pieza
4065	25303171	020.000.3835.01 Vitamina A	Pieza
4066	25303172	010.000.2715.01 Vitamina E	Pieza
4067	25303173	010.000.2715.00 Vitamina E	Pieza
4068	25303175	010.000.5383.00 Vitaminas (polivitaminas) y minerales	Pieza
4069	25303176	010.000.2710.00 Vitaminas y minerales	Pieza
4070	25303177	010.000.4331.01 Zafirlukast	Pieza
4071	25303178	010.000.4361.00 Zolmitriptano	Pieza
4072	25303179	010.000.4361.01 Zolmitriptano	Pieza
4073	25303180	010.000.5484.00 Zuclopentixol	Pieza
4074	25303181	010.000.5484.01 Zuclopentixol	Pieza
4075	25303182	010.000.6083.00 Citrato de cafeina	Pieza
4076	25303183	010.000.6083.01 Citrato de cafeina	Pieza
4077	25303184	010.000.6085.00 Brentuximab vedotin	Pieza
4078	25303185	010.000.6086.00 Carfilzomib	Pieza
4079	25303186	010.000.5631.01 Alprostadil	Pieza
4080	25303187	010.000.5171.02 Octreotida	Pieza
4081	25303188	010.000.6087.00 Alirocumab	Pieza
4082	25303189	010.000.6087.01 Alirocumab	Pieza
4083	25303190	010.000.6087.02 Alirocumab	Pieza
4084	25303191	010.000.6087.03 Alirocumab	Pieza
4085	25303192	010.000.6087.04 Alirocumab	Pieza
4086	25303193	010.000.6087.05 Alirocumab	Pieza
4087	25303194	010.000.6088.00 Alirocumab	Pieza
4088	25303195	010.000.6088.01 Alirocumab	Pieza
4089	25303196	010.000.6088.02 Alirocumab	Pieza
4090	25303197	010.000.6088.03 Alirocumab	Pieza
4091	25303198	010.000.6088.04 Alirocumab	Pieza
4092	25303199	010.000.6088.05 Alirocumab	Pieza
4093	25303200	010.000.6089.00 Evolocumab	Pieza
4094	25303201	010.000.6089.01 Evolocumab	Pieza
4095	25303202	010.000.6090.00 Emtricitabina/rilpivirina/tenofovir	Pieza
4096	25303203	010.000.6091.00 Bromuro de aclidinio / formoterol	Pieza
4097	25303204	010.000.6092.00 Teriflunomida	Pieza
4098	25303205	010.000.6093.00 Ruxolitinib	Pieza
4099	25303206	010.000.6094.00 Ruxolitinib	Pieza
4100	25303207	010.000.6095.00 Ruxolitinib	Pieza
4101	25303208	010.000.4186.05 Mesalazina	Pieza
4102	25303209	010.000.4186.06 Mesalazina	Pieza
4103	25303210	010.000.4186.07 Mesalazina	Pieza
4104	25303211	010.000.4363.00 Acetato de glatiramer	Pieza
4105	25303212	010.000.6036.00 Acetato de glatiramer	Pieza
4106	25303225	010.000.6098.00 Darunavir/Cobicistat	Pieza
4107	25303226	010.000.6099.00 Lactulosa	Pieza
4108	25303227	010.000.6099.01 Lactulosa	Pieza
4109	25303228	010.000.6100.00 Lactulosa	Pieza
4110	25303229	010.000.6101.00 Complejo de Protrombina Humana	Pieza
4111	25303230	010.000.6102.00 Complejo de Protrombina Humana	Pieza
4112	25303231	010.000.0615.01 Dobutamina	Pieza
4113	25303232	010.000.6084.00 Sevelamero	Pieza
4114	25303233	010.000.6103.00 Riociguat	Pieza
4115	25303234	010.000.6104.00 Riociguat	Pieza
4116	25303235	010.000.6105.00 Riociguat	Pieza
4117	25303236	010.000.6106.00 Riociguat	Pieza
4118	25303237	010.000.6107.00 Riociguat	Pieza
4119	25303238	010.000.6096.00 Blinatumomab	Pieza
4120	25303239	010.000.6097.00 Enzalutamida	Pieza
4121	25303240	010.000.6108.00 Dolutegravir/Abacavir/Lamivudina	Pieza
4122	25303241	010.000.6109.00 Nivolumab	Pieza
4123	25303242	010.000.6110.00 Nivolumab	Pieza
4124	25303243	010.000.6111.00 Tofacitinib	Pieza
4125	25303244	010.000.6111.01 Tofacitinib	Pieza
4126	25303245	010.000.4238.02 Eptacog alfa (Factor de coagulacion VII alfa recombinante)	Pieza
4127	25303246	010.000.4245.02 Eptacog alfa (Factor de coagulacion VII alfa recombinante)	Pieza
4128	25303247	010.000.4250.02 Eptacog alfa (Factor de coagulacion VII alfa recombinante)	Pieza
4129	25303248	010.000.4512.03 Adalimumab	Pieza
4130	25303250	Fosfomicina calcica monohidratada	Pieza
4131	25303251	Formula enteral especializada para perdida de peso involuntaria	Pieza
4132	25303252	Fluroceina	Pieza
4133	25303253	Melatonina	Pieza
4134	25303254	010.000.6112.00 Sacubitrilo valsartan	Pieza
4135	25303255	010.000.6113.00 Sacubitrilo valsartan	Pieza
4136	25303256	010.000.6114.00 Sacubitrilo valsartan	Pieza
4137	25303257	010.000.6115.00 Selegilina	Pieza
4138	25303260	Glutamina	Pieza
4139	25303261	Citrato de sufentanilo	Pieza
4140	25303262	Dexketoprofeno trometamol	Pieza
4141	25303263	Etamsilato	Pieza
4142	25303264	Formula enteral especializada para adulto mayor con malnutricion	Pieza
4143	25303265	Formula enteral especializada para enfermedades pulmonares	Pieza
4144	25303266	Formula enteral especializada para pacientes en dialisis	Pieza
4145	25303267	Formula enteral polimerica especializada para pacientes con insuficiencia hepatica, encefalopatica aguda o cronica y para pacientes en el post transplante hepatico inmediato o tardio	Pieza
4146	25303268	Lauromacrogol	Pieza
4147	25303269	Posaconazol	Pieza
4148	25303270	Tropicamida y fenilefrina	Pieza
4149	25303271	Amoxicilina con sulbatam	Pieza
4150	25303272	Daptomicina	Pieza
4151	25303273	Ceftolozano con tazobactam	Pieza
4152	25303274	Tedizolid fosfato	Pieza
4153	25303275	Ceftarolina fosamilo	Pieza
4154	25303276	Bumetanida	Pieza
4155	25303277	010.000.6116.00 Agalsidasa beta	Pieza
4156	25303278	010.000.6117.00 Insulina aspartica (30% de insulina asparta soluble y 70% insulina asparta cristalina con protamina)	Pieza
4157	25303279	010.000.6117.01 Insulina aspartica (30% de insulina asparta soluble y 70% insulina asparta cristalina con protamina)	Pieza
4158	25303280	010.000.6119.00 Dexametasona	Pieza
4159	25303281	010.000.6118.00 Aflibercept	Pieza
4160	25303282	010.000.6120.00 Lipegfilgrastim	Pieza
4161	25303283	010.000.6121.00 Zidovudina	Pieza
4162	25303284	010.000.6122.00 Amfotericina B liposomal	Pieza
4163	25303285	010.000.6054.01 Exenatida	Pieza
4164	25303286	010.000.6129.00 Racecadotrilo	Pieza
4165	25303287	010.000.6130.00 Racecadotrilo	Pieza
4166	25303288	010.000.6123.00 Alogliptina	Pieza
4167	25303289	010.000.6124.00 Cisteamina	Pieza
4168	25303290	010.000.6125.00 Cisteamina	Pieza
4169	25303291	010.000.6126.00 Elvitegravir/cobicistat/emtricitabina/tenofovir	Pieza
4170	25303292	010.000.6127.00 Grazoprevir/elbasvir	Pieza
4171	25303293	010.000.6131.00 Sofosbuvir, velpatasvir	Pieza
4172	25303294	030.000.6128.00 Nutricion parenteral a base de lipidos, aminoacidos, glucosa, electrolitos	Pieza
4173	25303295	030.000.6128.01 Nutricion parenteral a base de lipidos, aminoacidos, glucosa, electrolitos	Pieza
4174	25303296	030.000.6128.02 Nutricion parenteral a base de lipidos, aminoacidos, glucosa, electrolitos	Pieza
4175	25303297	030.000.6128.03 Nutricion parenteral a base de lipidos, aminoacidos, glucosa, electrolitos	Pieza
4176	25303298	010.000.6132.00 Anfotericina B (Complejo fosfolipido o lipidico)	Pieza
4177	25303299	010.000.6133.00 Idarucizumab	Pieza
4178	25303300	010.000.6134.00 Fenofibrato	Pieza
4179	25303301	010.000.6134.01 Fenofibrato	Pieza
4180	25303302	020.000.6135.00 Vacuna contra difteria, tos ferina, tetanos, hepatitis b, poliomielitis y haemophilus influenzae tipo b	Pieza
4181	25303303	010.000.5720.02 Paracetamol	Pieza
4182	25303304	010.000.5721.02 Paracetamol	Pieza
4183	25303305	010.000.5920.01 Ribavirina	Pieza
4184	25303307	Carboximaltosa ferrica	Pieza
4185	25303310	Temsirolimus	Pieza
4186	25303311	Trabectedina	Pieza
4187	25303312	040.000.6140.00 Tramadol	Pieza
4188	25303313	040.000.6140.01 Tramadol	Pieza
4189	25303314	040.000.6141.00 Tramadol	Pieza
4190	25303315	040.000.6141.01 Tramadol	Pieza
4191	25303316	010.000.6136.00 Rilpivirina	Pieza
4192	25303317	010.000.6137.00 Eritropoyetina theta	Pieza
4193	25303318	010.000.6138.00 Eritropoyetina theta	Pieza
4194	25303320	010.000.6142.00 Palbociclib	Pieza
4195	25303321	010.000.6143.00 Palbociclib	Pieza
4196	25303322	010.000.6144.00 Palbociclib	Pieza
4197	25303323	010.000.6145.00 Pomalidomida	Pieza
4198	25303324	010.000.6146.00 Pomalidomida	Pieza
4199	25303325	010.000.6147.00 Pomalidomida	Pieza
4200	25303326	010.000.6148.00 Pomalidomida	Pieza
4201	25303327	010.000.5206.02 Folitropina beta o folitropina alfa	Pieza
4202	25303328	010.000.4308.02 Sildenafil	Pieza
4203	25303329	020.000.3825.04 Vacuna contra la Hepatitis A	Pieza
4204	25303330	020.000.3825.07 Vacuna contra la Hepatitis A	Pieza
4205	25303331	020.000.3825.08 Vacuna contra la Hepatitis A	Pieza
4206	25303332	020.000.3825.09 Vacuna contra la Hepatitis A	Pieza
4207	25303333	010.000.6149.00 Afatinib	Pieza
4208	25303334	010.000.4289.01 Darunavir	Pieza
4209	25303335	010.000.5860.01 Darunavir	Pieza
4210	25303336	010.000.4396.01 Emtricitabina-Tenofovir	Pieza
4211	25303337	010.000.6151.00 Acido Carglumico	Pieza
4212	25303338	010.000.6151.01 Acido Carglumico	Pieza
4213	25303339	010.000.6150.00 Budesonida	Pieza
4214	25303340	010.000.5544.01 Rivaroxaban	Pieza
4215	25303341	010.000.6152.00 Hemina Humana	Pieza
4216	25303342	010.000.6153.00 Pembrolizumab	Pieza
4217	25303343	010.000.6154.00 Golimumab	Pieza
4218	25303344	010.000.0244.00 Propofol	Pieza
4219	25303345	010.000.1501.00 Estrogenos conjugados	Pieza
4220	25303346	010.000.6067.01 Nintedanib	Pieza
4221	25303347	010.000.6139.00 Bosentan	Pieza
4222	25303348	Amoxicilina - acido clavulanico	Pieza
4223	25303351	Clofazimina	Pieza
4224	25303352	Delamanida	Pieza
4225	25303361	Prothionamida	Pieza
4226	25303363	Doxiciclina liofilizado	Pieza
4227	25303364	010.000.6155.00 Betaina anhidra	Pieza
4228	25303365	010.000.6156.00 Factor de crecimiento epidermico humano recombinante (FCEhr)	Pieza
4229	25303366	010.000.6157.00 Beclometasona/Formoterol	Pieza
4230	25303367	010.000.6158.00 Olaparib	Pieza
4231	25303368	040.000.4477.01 Haloperidol	Pieza
4232	25303369	010.000.2738.00 Aminoacidos cristalinos	Pieza
4233	25303370	010.000.4376.00 Multivitaminas (Polivitaminas) y Minerales	Pieza
4234	25303371	010.000.6500.00 Glucosa / Aminoacidos / Electrolitos / Lipidos	Pieza
4235	25303372	Benznidazol	Pieza
4236	25303373	Glucantime antimoniato de meglumina	Pieza
4237	25303374	010.000.6159.00 Regorafenib	Pieza
4238	25303375	010.000.6159.01 Regorafenib	Pieza
4239	25303376	010.000.6160.00 Levonorgestrel	Pieza
4240	25303377	010.000.6161.00 Elvitegravir/Cobicistat/Emtricitabina/Tenofovir Alafenamida	Pieza
4241	25303378	010.000.6162.00 Emtricitabina/Tenofovir Alafenamida	Pieza
4242	25303379	010.000.6163.00 Emtricitabina/Tenofovir Alafenamida	Pieza
4243	25303380	010.000.6164.00 Glecaprevir/Pibrentasvir	Pieza
4244	25303381	010.000.6165.00 Ribociclib	Pieza
4245	25303382	010.000.6034.01 Mifepristona	Pieza
4246	25303383	030.000.6501.00 Formula Para Lactantes Con Necesidades Especiales De Nutricion De 22 Kcal/Oz Fl	Pieza
4247	25303384	030.000.6502.00 Formula Para Lactantes Con Necesidades Especiales De Nutricion De 24 Kcal/Oz Fl	Pieza
4248	25303385	030.000.6502.01 Formula Para Lactantes Con Necesidades Especiales De Nutricion De 24 Kcal/Oz Fl	Pieza
4249	25303386	030.000.6503.00 Formula Para Lactantes Con Necesidades Especiales De Nutricion De 24 Kcal/Oz Fl Alto En Proteina	Pieza
4250	25303387	030.000.6504.00 Formula Para Lactantes Con Necesidades Especiales De Nutricion 27 Kcal/Oz Fl	Pieza
4251	25303388	030.000.6505.00 Formula Para Lactantes Con Necesidades Especiales De Nutricion De 30 Kcal/Oz Fl	Pieza
4252	25303389	030.000.6506.00 Formula Para Lactantes Con Necesidades Especiales De Nutricion, Fortificador De Leche Materna O Humana	Pieza
4253	25303390	030.000.6506.01 Formula Para Lactantes Con Necesidades Especiales De Nutricion, Fortificador De Leche Materna O Humana	Pieza
4254	25303391	010.000.6500.01 Glucosa/Aminoacidos/Electrolitos/Lipidos	Pieza
4255	25303392	030.000.0011.01 Sucedaneo de leche humana de termino	Pieza
4256	25303393	030.000.0014.01 Formula de seguimiento o continuacion con o sin probioticos	Pieza
4257	25303394	030.000.0013.01 Formula de proteina extensamente hidrolizada	Pieza
4258	25303395	030.000.5394.01 Formula de proteina extensamente hidrolizada con trigliceridos de cadena media	Pieza
4259	25303396	Parecoxib	Pieza
4260	25303397	010.000.6166.00 Cloruro de radio 223	Pieza
4261	25303398	010.000.6156.01 Factor de drecimiento epidermico humano recombinante (FCEhr)	Pieza
4262	25303399	010.000.4217.01 Progesterona	Pieza
4263	25303400	020.000.6167.00 Faboterapico polivalente antiaracnido	Pieza
4264	25303401	010.000.6168.00 Sugammadex	Pieza
4265	25303402	010.000.6169.00 Levotiroxina sodica	Pieza
4266	25303403	010.000.6170.00 Levotiroxina sodica	Pieza
4267	25303404	010.000.6171.00 Lenvatinib	Pieza
4268	25303405	010.000.6172.00 Lenvatinib	Pieza
4269	25303406	010.000.6173.00 Osimertinib	Pieza
4270	25303407	010.000.6174.00 Palonosetron/Netupitant	Pieza
4271	25303408	040.000.6175.00 Oxicodona/Naloxona	Pieza
4272	25303409	040.000.6176.00 Oxicodona/Naloxona	Pieza
4273	25303410	040.000.6177.00 Oxicodona/Naloxona	Pieza
4274	25303411	010.000.6178.00 Ixekizumab	Pieza
4275	25303412	010.000.6179.00 Alogliptina/Metformina	Pieza
4276	25303413	010.000.6180.00 Alogliptina/Metformina	Pieza
4277	25303414	010.000.6181.00 Alogliptina/Pioglitazona	Pieza
4278	25303415	010.000.6182.00 Alogliptina/Pioglitazona	Pieza
4279	25303416	010.000.6183.00 Ulipristal	Pieza
4280	25303417	010.000.6184.00 Paclitaxel Unido A Albumina	Pieza
4281	25303418	010.000.6185.00 Baricitinib	Pieza
4282	25303419	010.000.6186.00 Baricitinib	Pieza
4283	25303420	020.000.6187.00 Vacuna Antihepatitis A	Pieza
4284	25303421	020.000.6187.01 Vacuna Antihepatitis A	Pieza
4285	25303422	Daratumumab	Pieza
4286	25303423	Atezolizumab	Pieza
4287	25303424	Nabpaclitaxel	Pieza
4288	25303425	Vacuna contra el meningococo	Pieza
4289	25303426	Vacuna contra la fiebre amarilla	Pieza
4290	25303427	Vacuna contra la herpes	Pieza
4291	25303428	040.000.6188.00 Fentanilo	Pieza
4292	25303429	040.000.6189.00 Fentanilo	Pieza
4293	25303430	040.000.6190.00 Fentanilo	Pieza
4294	25303431	040.000.6191.00 Fentanilo	Pieza
4295	25303432	040.000.6192.00 Fentanilo	Pieza
4296	25303433	010.000.5640.01 Efavirenz, Emtricitabina, Tenofovir Disoproxilo	Pieza
4297	25303434	Oxigeno medicinal	Pieza
4298	25303435	Aire medicinal	Pieza
4299	25303436	Bioxido de carbono	Pieza
4300	25303437	Nitrogeno medicinal	Pieza
4301	25303438	Oxido nitroso	Pieza
4302	25303439	010.000.6193.00 Atezolizumab	Pieza
4303	25303440	040.000.6194.00 Paliperidona	Pieza
4304	25303441	040.000.6195.00 Paliperidona	Pieza
4305	25303442	040.000.6196.00 Paliperidona	Pieza
4306	25303443	040.000.6197.00 Paliperidona	Pieza
4307	25303444	010.000.6198.00 Ceftolozano/Tazobactam	Pieza
4308	25303445	010.000.6203.00 Bictegravir/Emtricitabina/Tenofovir Alafenamida	Pieza
4309	25303446	Venetoclax	Pieza
4310	25303447	Acido Tranexamico	Pieza
4311	25303448	Tetrabenazina	Pieza
4312	25303449	Floroglucinol trimetrifluroglucinol	Pieza
4313	25303450	Nimesulida	Pieza
4314	25303451	Betametazona clotrimazona gentamicina	Pieza
4315	25303452	Sulcrafato	Pieza
4316	25303453	Trimebutina	Pieza
4317	25303454	Bencinamida	Pieza
4318	25303455	Antiseptico Fijo	Pieza
4319	2540	Materiales, accesorios y suministros medicos	
4320	25401	Materiales, accesorios y suministros medicos	
4321	25400001	Abatelenguas	Pieza
4322	25400002	Abrasivo para afilar cuchillas	Pieza
4323	25400003	Aceite hidrosoluble	Pieza
4324	25400004	Aceite lubricante para instrumental medico	Litro
4325	25400005	Aceite mineral para uso externo	Litro
4326	25400006	Acetona (uso medico)	Litro
4327	25400007	Acoplador de bolsa de transferencia para hemoferesis	Pieza
4328	25400008	Adaptadores para vaciado rapido de soluciones	Pieza
4329	25400009	Aditamento de inflado para balones de cateteres	Pieza
4330	25400010	Agitador manual	Pieza
4331	25400011	Agua oxigenada	Pieza
4332	25400012	Aguja de cournand	Pieza
4333	25400013	Aguja de seldinger	Pieza
4334	25400014	Aguja dental	Pieza
4335	25400015	Aguja hipodermica	Pieza
4336	25400016	Aguja monopolar	Pieza
4337	25400017	Aguja para anestesia	Pieza
4338	25400018	Aguja para angiografia	Pieza
4339	25400019	Aguja para aortografia	Pieza
4340	25400020	Aguja para biopsia	Pieza
4341	25400021	Aguja para cateterismo	Pieza
4342	25400022	Aguja para localizar cavidades	Pieza
4343	25400023	Aguja para puncion de vasos	Pieza
4344	25400024	Aguja para raquianestesia	Pieza
4345	25400025	Aguja sutura	Pieza
4346	25400026	Alambre de acero para asas	Pieza
4347	25400027	Alambres para hueso	Pieza
4348	25400028	Alambres para ortodoncia	Pieza
4349	25400029	Alambres para osteosintesis	Pieza
4350	25400030	Alambres para polipotomo rectal aislado	Pieza
4351	25400031	Alcoholera portatil sala operaciones	Pieza
4352	25400032	Aleacion para amalgama dental (polvo)	Pieza
4353	25400033	Alginato para impresiones dentales	Pieza
4354	25400034	Algodon absorbente	Pieza
4355	25400035	Algodon esterilizado	Pieza
4356	25400036	Ampolleta (vacia)	Pieza
4357	25400037	Anclaje para la aplicacion de fuerza temporal	Pieza
4358	25400038	Anillo de soporte	Pieza
4359	25400039	Anillo de valvuloplastia	Pieza
4360	25400040	Aplicador de madera (sin algodon)	Pieza
4361	25400041	Aposito	Pieza
4362	25400042	Arco facial inverso para proteccion de segmento maxilar	Pieza
4363	25400043	Asa quirurgica	Pieza
4364	25400044	Bacinicas	Pieza
4365	25400045	Balon itraaortico de contrapulsacion	Pieza
4366	25400046	Banda adhesiva	Pieza
4367	25400047	Banda de acero inoxidable para premolares y molares	Pieza
4368	25400048	Barniz de copal (uso medico)	Pieza
4369	25400049	Barra metalica deerick para ferulizacion interdentaria	Pieza
4370	25400050	Biberones	Pieza
4371	25400051	Bicarbonato de sodio (polvo)	Pieza
4372	25400052	Bisturi (hoja)	Pieza
4373	25400053	Bisturis, escalpelos y lancetas	Pieza
4374	25400054	Block de silastic para implante	Pieza
4375	25400055	Bolsa almacenar sangre	Pieza
4376	25400056	Bolsa de hule natural o sintetico para agua caliente	Pieza
4377	25400057	Bolsa de hule natural o sintetico para hielo	Pieza
4378	25400058	Bolsa de hule para calibracion	Pieza
4379	25400059	Bolsa esteril para nutricion enteral	Pieza
4380	25400060	Bolsa fraccionar sangre	Pieza
4381	25400061	Bolsa mixta pelable con papel grado medico	Pieza
4382	25400062	Bolsa para alimentacion parenteral	Pieza
4383	25400063	Bolsa para dialisis peritoneal con glucosa	Pieza
4384	25400064	Bolsa para esterilizar en gas o vapor	Pieza
4385	25400065	Bolsa para ileostomia o colostomia (equipo)	Pieza
4386	25400066	Bolsa para urocultivo (niña) esteril de plastico	Pieza
4387	25400067	Bolsa para urocultivo (niño) esteril de plastico	Pieza
4388	25400068	Bolsa plasmaferesis	Pieza
4389	25400069	Bolsa transferencia sangre	Pieza
4390	25400070	Bolsas balon respiratorio electroconductor	Pieza
4391	25400071	Bolsas de plastico con resortes para recoleccion de aire espirado	Pieza
4392	25400072	Bolsas enema con canula de polietileno	Pieza
4393	25400073	Bolsas mixta pelable	Pieza
4394	25400074	Bolsas para ileostomia o colostomia	Pieza
4395	25400075	Bolsas para recibir solucion drenada de dialisis peritoneal (vacia)	Pieza
4396	25400076	Bolsas para recoleccion de orina	Pieza
4397	25400077	Botas para uso en quirofanos	Pieza
4398	25400078	Brazalete para identificacion	Pieza
4399	25400079	Brocas canuladas	Pieza
4400	25400080	Brocas cilindricas	Pieza
4401	25400081	Brocas especiales para perforador radiolucido	Pieza
4402	25400082	Brocas para acoplamiento rapido	Pieza
4403	25400083	Bureta	Pieza
4404	25400084	Cable guia con recubrimiento de teflon para vias biliares	Pieza
4405	25400085	Cal sodada con indicador	Pieza
4406	25400086	Camisa anestesia	Pieza
4407	25400087	Camisa receptor	Pieza
4408	25400088	Campana con circuito integrado para hemoferesis adulto	Pieza
4409	25400089	Campana con circuito integrado para hemoferesis infantil	Pieza
4410	25400090	Campos quirurgicos	Pieza
4411	25400091	Candelilla de plastico acopleable a la sonda	Pieza
4412	25400092	Canula	Pieza
4413	25400093	Canula vacia gelatina	Pieza
4414	25400186	Electrodo de tierra con terminacion en argolla	Pieza
4415	25400094	Capsulas para perdigon metalico para amalgamador electrico	Pieza
4416	25400095	Capuchones de proteccion para biberon	Pieza
4417	25400096	Cartucho esteril para engrapadora lineal	Pieza
4418	25400097	Cartucho para bomba de infusion para aplicacion medica	Pieza
4419	25400098	Cartucho para crioestractor (aerosol)	Pieza
4420	25400099	Cartucho para torniquete neumatico de aire acondicionado	Pieza
4421	25400100	Cateter	Pieza
4422	25400101	Cateter con balon de dilatacion defascia y renal	Pieza
4423	25400102	Cemento de iomomero de vidrio con aleacion de limadura	Pieza
4424	25400103	Cemento de iomomero de vidrio restaurativo	Pieza
4425	25400104	Cemento dental de oxido de zinc con endurecedor polvo/liquido	Pieza
4426	25400105	Cemento dental para sellar conductos radiculares  (polvo)	Pieza
4427	25400106	Cemento para craneo plastia en polvo (metilmetacrilato) solvente	Pieza
4428	25400107	Cemento para hueso polimetilmetacrilato doble velocidad	Pieza
4429	25400108	Cemento para uso quirurgico  (liquido)	Pieza
4430	25400109	Cepillero para uso quirurgico	Pieza
4431	25400110	Cepillo de fibra vegetal (lechuguilla) para lavar instrumental	Pieza
4432	25400111	Cepillo dental	Pieza
4433	25400112	Cepillo para pulido de amalgamas y profilaxis	Pieza
4434	25400113	Cera (pasta de breck) para huesos esteril	Pieza
4435	25400114	Cera rosa para uso dental	Pieza
4436	25400115	Cera sellar	Pieza
4437	25400116	Cilindro de vidrio para jeringa metalica para angioplastia	Pieza
4438	25400117	Cinta metalica porta matriz de amalgama	Pieza
4439	25400118	Cinta metrica ahulada, graduada en cms. Y mts.	Pieza
4440	25400119	Cinta microporosa	Pieza
4441	25400120	Cinta testigo para esterilizacion	Pieza
4442	25400121	Cinta umbilical de algodon	Pieza
4443	25400122	Clavos intramedulares condilo cefalico	Pieza
4444	25400123	Clavos intramedulares para femur	Pieza
4445	25400124	Clavos intramedulares para tibia	Pieza
4446	25400125	Clavos para femur	Pieza
4447	25400126	Clavos para hueso (punta triangular)	Pieza
4448	25400127	Clavos para tibia	Pieza
4449	25400128	Clip hemostatico plano de teflon	Pieza
4450	25400129	Colodion elastico	Pieza
4451	25400130	Colorante revelador de placa dento bacteriana (tabletas)	Pieza
4452	25400131	Columna instrumentacion	Pieza
4453	25400132	Compas raquia desechable	Pieza
4454	25400133	Compresa	Pieza
4455	25400134	Conector con linea de transferencia	Pieza
4456	25400135	Conector en "y" para cateteres de angioplastia	Pieza
4457	25400136	Conector en "y" para guia nyler	Pieza
4458	25400137	Conector grueso de plastico de una via	Pieza
4459	25400138	Conectores de 2 vias	Pieza
4460	25400139	Conectores de plastico	Pieza
4461	25400140	Conectores de plastico con transparencia de cristal	Pieza
4462	25400141	Conectores de plastico de una via	Pieza
4463	25400142	Conectores de plastico para hidrocefalia	Pieza
4464	25400143	Conectores de titanio	Pieza
4465	25400144	Conectores linea de transferencia de silastic esteril	Pieza
4466	25400145	Conectores metalicos con entrada macho o hembra	Pieza
4467	25400146	Conformador de la protesis de ojo para enucleacion	Pieza
4468	25400147	Cono plato	Pieza
4469	25400148	Copa para pieza de mano de hule suave forma de cono	Pieza
4470	25400149	Cubre boca	Pieza
4471	25400150	Cubre objetos	Pieza
4472	25400151	Cucharilla para aplicacion topica de fluor	Pieza
4473	25400152	Cuchilla para ureterotomo (hueca)	Pieza
4474	25400153	Cuchilla para ureterotomo recta	Pieza
4475	25400154	Cuchilla para ureterotomo semilunar	Pieza
4476	25400155	Cuerda de algodon para motor baja velocidad (estandar)	Pieza
4477	25400156	Cuerda guia para angioplastia coronaria	Pieza
4478	25400157	Cuerda guia para remplazo de cateter	Pieza
4479	25400158	Cuerda guia teflonada para cateter con punta recta alma Mobil	Pieza
4480	25400159	Cuerda guia teflonada para cateter de punta en "j"	Pieza
4481	25400160	Cuñas de madera	Pieza
4482	25400161	Curitas	Pieza
4483	25400162	Dedo hule	Pieza
4484	25400163	Dializador para hemodialisis (desechable)	Pieza
4485	25400164	Dilatador renal de teflon o polietileno esteril	Pieza
4486	25400165	Dilatador ureteral de polietileno o teflon	Pieza
4487	25400166	Dilatador ureteral hidraulico	Pieza
4488	25400167	Director de fibra	Pieza
4489	25400168	Director de fibra doble efecto	Pieza
4490	25400169	Director de fibra hemisferica	Pieza
4491	25400170	Disco de fuerza	Pieza
4492	25400171	Disco de manta de uso dental	Pieza
4493	25400172	Disco de mica para valvula espirometrica en "y"	Pieza
4494	25400173	Disco implante de acero inoxidable para nutricion parental	Pieza
4495	25400174	Disco para separar, lijar o cortar dientes de carbono acero	Pieza
4496	25400175	Disco para separar, lijar o cortar dientes de carburo	Pieza
4497	25400176	Dispositivo de hemostasia para cateter de dilatacion	Pieza
4498	56300128	Tirafondeadora simple	Pieza
4499	25400177	Dispositivo intrauterino (anticonceptivo) esteril "t"	Pieza
4500	25400178	Electrodo copa de oro	Pieza
4501	25400179	Electrodo copa de plata	Pieza
4502	25400180	Electrodo de aguja	Pieza
4503	25400181	Electrodo de barra	Pieza
4504	25400182	Electrodo de broche	Pieza
4505	25400183	Electrodo de placa de aluminio	Pieza
4506	25400184	Electrodo de placa esponja viscosa	Pieza
4507	25400185	Electrodo de tierra	Pieza
4508	25400187	Electrodo para marcapaso definitivo bipolar endocardiaco	Pieza
4509	25400188	Electrodo para marcapaso definitivo endocardiaco en "j"	Pieza
4510	25400189	Electrodo para uretero resectoscopio coagulador	Pieza
4511	25400190	Electrodo para uretero resectoscopio cortante	Pieza
4512	25400191	Electrodo para uretero resectoscopio de gancho	Pieza
4513	25400192	Electrodo puntual con conector black spencer	Pieza
4514	25400193	Electrodo puntual con terminacion black mayer	Pieza
4515	25400194	Electrodos para litotriptor electro hidraulico vesical	Pieza
4516	25400195	Endoiluminador de fibra optica	Pieza
4517	25400196	Endroprueba curva para endofotocoagulacion	Pieza
4518	25400197	Endroprueba recta para endofotocoagulacion	Pieza
4519	25400198	Ensanchador de canales	Pieza
4520	25400199	Escalpelo para ureterotomo con afilado ondulado	Pieza
4521	25400200	Escalpelo para ureterotomo forma lanceolada	Pieza
4522	25400201	Escobillon	Pieza
4523	25400202	Espatula	Pieza
4524	25400203	Espejo para boca sin aumento	Pieza
4525	25400204	Esponja gasa	Pieza
4526	25400205	Esponja hemostatica de gelatina o de colageno	Pieza
4527	25400206	Esponjas neuroquirurgicas de algodon prensado	Pieza
4528	25400207	Estilete oclusor para cateter transeptal	Pieza
4529	25400208	Expansores de piel de silicon	Pieza
4530	25400209	Extractor de grapas para piel	Pieza
4531	25400210	Eyector de saliva de plastico	Pieza
4532	25400211	Ferula	Pieza
4533	25400212	Fibra optica corta	Pieza
4534	25400213	Fibra optica corta tipo "s" conico	Pieza
4535	25400214	Fibra optica corta tipo "s" de doble efecto	Pieza
4536	25400215	Fibra optica corta tipo "s" hemisferica	Pieza
4537	25400216	Fibra optica sin contacto	Pieza
4538	25400217	Fijadores externos para mano y antebrazo	Pieza
4539	25400218	Fijadores externos tubulares para mano y antebrazo	Pieza
4540	25400219	Fijadores para alargamiento de extremidades y transporte	Pieza
4541	25400220	Filtro inhalacion	Pieza
4542	25400221	Filtro microagregado para perfusion	Pieza
4543	25400222	Filtro para sangre	Pieza
4544	25400223	Filtro purificador compresor	Pieza
4545	25400224	Filtro venoso	Pieza
4546	25400225	Formas de acero inoxidable para coronas	Pieza
4547	25400226	Fresa (odontologia)	Pieza
4548	25400227	Fundente para soldadura de plata de uso dental	Pieza
4549	25400228	Gancho de adams para ortodoncia	Pieza
4550	25400229	Gancho de bola para ortodoncia	Pieza
4551	25400230	Gasa esterilizada	Pieza
4552	25400231	Goma de karaya (polvo)	Pieza
4553	25400232	Gorro para cirujano	Pieza
4554	25400233	Gorro para pacientes y enfermeras	Pieza
4555	25400234	Grapas de nemackensie	Pieza
4556	25400235	Grapas hemostaticas de titanium ferronomagnetico	Pieza
4557	25400236	Grapas para aneurismas	Pieza
4558	25400237	Grapas para epefisis de cromo cobalto	Pieza
4559	25400238	Grapas para fracturas de cromo cobalto	Pieza
4560	25400239	Grapas para osteostomia de cromo cobalto dentadas	Pieza
4561	25400240	Grapas para piel cabelluda metalicas	Pieza
4562	25400241	Grapas para selladora de bolsa de alimentacion parenteral	Pieza
4563	25400242	Guante para cirujano	Pieza
4564	25400243	Guantes cryo-glove	Pieza
4565	25400244	Guantes para exploracion	Pieza
4566	25400245	Guata quirurgica	Pieza
4567	25400246	Guia cateter	Pieza
4568	25400247	Guia de alambre recubierta de teflon	Pieza
4569	25400248	Guia metalica rigida con punta suave	Pieza
4570	25400249	Guia quirurgica	Pieza
4571	25400250	Guias para atornillo canulado grande con rosca en la punta	Pieza
4572	25400251	Guias para clavo condilo cefalico curva de punta roma	Pieza
4573	25400252	Guias para clavo de femur	Pieza
4574	25400253	Guias para tornillo dinamico de cadera y condilos	Pieza
4575	25400254	Hilo sutura	Pieza
4576	25400255	Hoja desechable para queratoplastia (trepano)	Pieza
4577	25400256	Hojas para sierra cortadora de yeso	Pieza
4578	25400257	Hojas para sierra oscilatoria de hueso para cirugia osea	Pieza
4579	25400258	Horquilla interfemoral	Pieza
4580	25400259	Implante cabeza cubito	Pieza
4581	25400260	Implante metacarpio	Pieza
4582	25400261	Implante oftamilco tipo bote simetrico	Pieza
4583	25400262	Implante oftamilco tipo llanta asimetrico	Pieza
4584	25400263	Injerto aortico valvulado	Pieza
4585	25400264	Injerto bifurcado corto femoral	Pieza
4586	25400265	Injerto bifurcado de albumina	Pieza
4587	25400266	Injerto bifurcado de gelatina	Pieza
4588	25400267	Injerto conico	Pieza
4589	25400268	Injerto conico regular	Pieza
4590	25400269	Injerto de dracon especial para uso especifico axilo bifemoral	Pieza
4591	25400270	Injerto de pared	Pieza
4592	25400271	Injerto de politetrafluoretileno bifurcado	Pieza
4593	25400272	Injerto de politetrafluoretileno tubular recto	Pieza
4594	25400273	Injerto para remplazo de arco aortico	Pieza
4595	25400274	Injerto pulmonar valvulado	Pieza
4596	25400275	Injerto reusable para pinza de fogarty	Pieza
4597	25400276	Injerto tubular (colagena de bovino)	Pieza
4598	25400277	Injerto tubular recto	Pieza
4599	25400278	Insertor guia para angioplastia coronaria	Pieza
4600	25400279	Instrumento engrapador circular de plast para anastomosis	Pieza
4601	25400280	Introductor de cateter arterial	Pieza
4602	25400281	Introductor de cateterismo transeptal	Pieza
4603	25400282	Introductor largo con valvula para vasos arteriales	Pieza
4604	25400283	Introductor para cateter venoso sin valvula	Pieza
4605	25400284	Introductor para electrodo de marcapaso definitivo	Pieza
4606	25400285	Introductor para electrodo de marcapaso temporal	Pieza
4607	25400286	Introductores de cateteres arterial o venoso	Pieza
4608	25400287	Inyector para varisis esofagicas	Pieza
4609	25400288	Isopo	Pieza
4610	25400289	Isotopos radiactivos	Pieza
4611	25400290	Jabon quirurgico	Pieza
4612	25400291	Jalea lubricante aseptica	Pieza
4613	25400292	Jeringa anioscardio	Pieza
4614	25400293	Jeringa automatica	Pieza
4615	25400294	Jeringa c/aguja desechable	Pieza
4616	25400295	Jeringa de plastico para angiografia y arteriografia	Pieza
4617	25400296	Jeringa de plastico para inflar el globo del cateter	Pieza
4618	25400297	Jeringa de plastico sin aguja	Pieza
4619	25400298	Jeringa hipodermica	Pieza
4620	25400299	Jeringa laringe	Pieza
4621	25400300	Jeringa micrometrica	Pieza
4622	25400301	Lamina de acero inoxidable para cirugia maxilofacial	Pieza
4623	25400302	Lampara de alcohol	Pieza
4624	25400303	Lanceta (hoja)	Pieza
4625	25400304	Ligas de hule y latex  (extrabucales)	Pieza
4626	25400305	Ligas de ortodoncia	Pieza
4627	25400306	Llave de cuatro vias	Pieza
4628	25400307	Llave de tres vias	Pieza
4629	25400308	Loseta para abatir cemento de vidrio	Pieza
4630	25400309	Lubricante glicerina	Pieza
4631	25400310	Machuelos con anclaje rapido para cirugia maxilofacial	Pieza
4632	25400311	Machuelos con cierre dental para cirugia maxilofacial	Pieza
4633	25400312	Maletin medico	Pieza
4634	25400313	Malla de polipropileno anudado	Pieza
4635	25400314	Mamila de hule latex, repuesto para biberon	Pieza
4636	25400315	Manga de irrigacion para vitectromia de silicon	Pieza
4637	25400316	Mango bisturi	Pieza
4638	25400317	Manguera inhalacion	Pieza
4639	25400318	Manguera para anestesia corrugada	Pieza
4640	25400319	Manometro para controlar la presion	Pieza
4641	25400320	Marcapasos	Pieza
4642	25400321	Mascara anti-gas (uso medico)	Pieza
4643	25400322	Mascarilla para administrar oxigeno (desechable)	Pieza
4644	25400323	Mentonera de acrilico forrada con fieltro	Pieza
4645	25400324	Oblea	Pieza
4646	25400325	Oclusor	Pieza
4647	25400326	Oxigenador de membrana silicon devanada	Pieza
4648	25400327	Oxigenador para circulacion extracorporea de membrana	Pieza
4649	25400328	Pañales predoblados adulto	Pieza
4650	25400329	Pañales predoblados para niños (grande)	Pieza
4651	25400330	Paño para exprimir amalgama	Pieza
4652	25400331	Papel cardiostat prueba de esfuerzo	Pieza
4653	25400332	Papel electrico/ecu	Pieza
4654	25400333	Papel fotosensible	Pieza
4655	25400334	Papel graficador sma	Pieza
4656	25400335	Papel indicador de contacto oclusal	Pieza
4657	25400336	Papel metabolismo basal	Pieza
4658	25400337	Papel para cardiografo fetal	Pieza
4659	25400338	Papel para electro fetal	Pieza
4660	25400339	Papel para electrocardiografo	Pieza
4661	25400340	Papel para electrocardiografo termosensible	Pieza
4662	25400341	Papel para electroencefalografo	Pieza
4663	25400342	Papel para fono cardiografo	Pieza
4664	25400343	Papel termosensible	Pieza
4665	25400344	Papel termosensible para monitor	Pieza
4666	25400345	Papel termosensible plegable	Pieza
4667	25400346	Papel termosensible prueba de esfuerzo	Pieza
4668	25400347	Papel tornasol	Pieza
4669	25400348	Parche de dracon de baja porosidad	Pieza
4670	25400349	Parche de fieltro de teflon	Pieza
4671	25400350	Parche de malla de poliester (trenzado)	Pieza
4672	25400351	Pasta abrasiva para profilaxis dental	Pieza
4673	25400352	Pasta conductora para potenciales evocados	Pieza
4674	25400353	Pasta electrodo	Pieza
4675	25400354	Pasta pulidora de metales (rojo ingles)	Pieza
4676	25400355	Pasta tripoli para pulir acrilico y metal	Pieza
4677	25400356	Patron p-cpk	Pieza
4678	25400357	Patron q-pack	Pieza
4679	25400358	Pera de hule para aspiracion de secreciones	Pieza
4680	25400359	Pernos para clavo	Pieza
4681	25400360	Pernos para clavo de tibia	Pieza
4682	25400361	Pernos para clavos de femur	Pieza
4683	25400362	Pichonera para bacinicas	Pieza
4684	25400363	Pieza de mano de irrigacion	Pieza
4685	25400364	Pinza de sujecion desechable	Pieza
4686	25400365	Placa desecador	Pieza
4687	25400366	Placa para cirugia maxilofacial arqueada	Pieza
4688	25400367	Placa para cirugia maxilofacial en "h" para tornillo	Pieza
4689	25400368	Placa para cirugia maxilofacial en "l" para tornillo	Pieza
4690	25400369	Placa para cirugia maxilofacial en "x" para tornillo	Pieza
4691	25400370	Placa para cirugia maxilofacial en "y" para tornillo	Pieza
4692	25400371	Placas anguladas para osteosintesis	Pieza
4693	25400372	Placas anguladas para osteotomia	Pieza
4694	25400373	Placas de titanio puro para piso de orbita para cirugia maxilofacial	Pieza
4695	25400374	Placas de titanio puro "h" para cirugia maxilofacial	Pieza
4696	25400375	Placas de titanio puro "l" derecha	Pieza
4697	25400376	Placas de titanio puro "l" izquierda	Pieza
4698	25400377	Placas de titanio puro "x" para cirugia maxilofacial	Pieza
4699	25400378	Placas de titanio puro "y" para cirugia maxilofacial	Pieza
4700	25400379	Placas de titanio puro de adaptacion	Pieza
4701	25400380	Placas de titanio puro de adaptacion para craneo	Pieza
4702	25400381	Placas de titanio puro de reconstruccion (angulada)	Pieza
4703	25400382	Placas de titanio puro de reconstruccion (recta)	Pieza
4704	25400383	Placas de titanio puro para arco sigomatico	Pieza
4705	25400384	Placas de titanio puro para orbita (arqueada)	Pieza
4706	25400385	Placas de titanio puro para piso orbital (universal)	Pieza
4707	25400386	Placas especiales con cabeza en forma de cobra	Pieza
4708	25400387	Placas especiales condileas de sosten	Pieza
4709	25400388	Placas especiales condileas de sosten (con orificios)	Pieza
4710	25400389	Placas especiales de angulo oblicuo	Pieza
4711	25400390	Placas especiales de sosten en "t"	Pieza
4712	25400391	Placas especiales de sosten en "t" (doble angulo)	Pieza
4713	25400392	Placas especiales de sosten lateral para tibia	Pieza
4714	25400393	Placas especiales en "l" para tornillos	Pieza
4715	25400394	Placas especiales en "t" (angulo recto)	Pieza
4716	25400395	Placas especiales en "t" para tornillos	Pieza
4717	25400396	Placas especiales en trebol para tornillos	Pieza
4718	25400397	Placas especiales para reconstruccion (arqueada)	Pieza
4719	25400398	Placas especiales para reconstruccion (rectas)	Pieza
4720	25400399	Placas especiales para vertebras cervicales	Pieza
4721	25400400	Placas para cirugia maxilofacial (con orificios)	Pieza
4722	25400401	Placas para cirugia maxilofacial (tipo maya)	Pieza
4723	25400402	Placas para cirugia maxilofacial para reconstruccion (angulo)	Pieza
4724	25400403	Placas para cirugia maxilofacial para reconstruccion (recta)	Pieza
4725	25400404	Placas para cirugia maxilofacias para piso orbitario	Pieza
4726	25400405	Placas para reconstruccion maxilofacial	Pieza
4727	25400406	Placas para tornillo dinamico de cadera	Pieza
4728	25400407	Placas para tornillo dinamico de condilo	Pieza
4729	25400408	Placas rectas anchas (con orificios)	Pieza
4730	25400409	Placas rectas angostas (con orificios)	Pieza
4731	25400410	Placas rectas semitubulares	Pieza
4732	25400411	Polea rehabilitacion	Pieza
4733	25400412	Polvo de piedra pomez para uso dental	Pieza
4734	25400413	Porta amalgama	Pieza
4735	25400414	Porta impresiones dentales	Pieza
4736	25400415	Porta lentes (experimentos opticos)	Pieza
4737	25400416	Porta termometros	Pieza
4738	25400417	Portapantallas	Pieza
4739	25400418	Preservativos de hule latex	Pieza
4740	25400419	Protector cara dentista	Pieza
4741	25400420	Protector pulpar para sellar cavidades, dentales	Pieza
4742	25400421	Protesis	Pieza
4743	25400422	Pruebas testigo biologicas	Pieza
4744	25400423	Puntas absorbente para endodoncia	Pieza
4745	25400424	Puntas absorbentes de papel (esteriles)	Pieza
4746	25400425	Puntas de gatupercha	Pieza
4747	25400426	Rastrillos (desechables)	Pieza
4748	25400427	Recolector de punzocortantes (desechables)	Pieza
4749	25400428	Reservorio de cardiotomia	Pieza
4750	25400429	Reservorio para liquido cefalorraquideo	Pieza
4751	25400430	Resina acrilica autopolimerizable (liquida)	Pieza
4752	25400431	Resina acrilica autopolimerizable, rosa (polvo)	Pieza
4753	25400432	Rollos y hojas radiograficas (uso medico)	Pieza
4754	25400433	Rondanas (arandelas ) para reinsercion de ligamentos	Pieza
4755	25400434	Rondanas (arandelas) metalicas	Pieza
4756	25400435	Sellador de fisuras resina de microrrelleno	Pieza
4757	25400436	Separador liquido (para yeso y acrilico)	Pieza
4758	25400437	Soldadura de plata para uso dental	Pieza
4759	25400438	Solucion para reseccion transuretral de glicina	Pieza
4760	25400439	Solucion preservadora de organos eurocollins	Pieza
4761	25400440	Sonda anestesia	Pieza
4762	25400441	Sonda bronquial	Pieza
4763	25400442	Sonda de nutricion enteral de poliuretano	Pieza
4764	25400443	Sonda de silastic para drenaje toraxico	Pieza
4765	25400444	Sonda de yeyunost especial para nutricion	Pieza
4766	25400445	Sonda enbolectomia o trombectomia	Pieza
4767	25400446	Sonda esofago	Pieza
4768	25400447	Sonda estomago	Pieza
4769	25400448	Sonda gastrointestinal	Pieza
4770	25400449	Sonda introduccion cobalto	Pieza
4771	25400450	Sonda maxilar	Pieza
4772	25400451	Sonda nasal	Pieza
4773	25400452	Sonda nefrostomia	Pieza
4774	25400453	Sonda para alimentacion	Pieza
4775	25400454	Sonda para aspirar secreciones	Pieza
4776	25400455	Sonda para drenaje con 4 aletas para autorretencion	Pieza
4777	25400456	Sonda para drenaje en forma de "t" de latex	Pieza
4778	25400457	Sonda para drenaje urinario de latex (con globo)	Pieza
4779	25400458	Sonda para drenaje urinario de latex (esteril)	Pieza
4780	25400459	Sonda para irrigacion continua de 3 vias con globo	Pieza
4781	25400460	Sonda para nutricion enteral con estilete	Pieza
4782	25400461	Sonda percusion regional periferica	Pieza
4783	25400462	Sonda punta redonda	Pieza
4784	25400463	Sonda punta redonda de latex	Pieza
4785	25400464	Sonda recto	Pieza
4786	25400465	Sonda traquea	Pieza
4787	25400466	Sonda trompas eustaquio	Pieza
4788	25400467	Sonda uretra	Pieza
4789	25400468	Sonda venoclisis	Pieza
4790	25400469	Suero sanguineo (substancias y productos farmaceuticos)	Pieza
4791	25400470	Suturas catgut cromico con aguja	Pieza
4792	25400471	Suturas catgut simple sin aguja	Pieza
4793	25400472	Suturas monofilamento nylon 2 (con aguja)	Pieza
4794	25400473	Suturas seda negra trenzada (con aguja)	Pieza
4795	25400474	Suturas seda negra trenzada (sin aguja)	Pieza
4796	25400475	Suturas sintetica absorbibles (con aguja)	Pieza
4797	25400476	Suturas sintetica no absorbibles (con aguja)	Pieza
4798	25400477	Tacon grande de hule para ferula de yeso	Pieza
4799	25400478	Talco para guantes quirurgicos	Pieza
4800	25400479	Talco para pacientes (compuesto de silicato de magnesio)	Pieza
4801	25400480	Tapa con rosca (repuesto para biberon)	Pieza
4802	25400481	Tapon para cateter de dialisis peritoneal ambulatoria	Pieza
4803	25400482	Tapon para cateter de hickman	Pieza
4804	25400483	Tapon para sonda de foley	Pieza
4805	25400484	Tapones esclerales	Pieza
4806	25400485	Taza de hule para batir yeso	Pieza
4807	25400486	Tela adhesiva	Pieza
4808	25400487	Termometro oral	Pieza
4809	25400488	Termometro rectal	Pieza
4810	25400489	Tintura de benjui	Pieza
4811	25400490	Tira de celuloide	Pieza
4812	25400491	Tira de deteccion o tirilla reactiva	Pieza
4813	25400492	Tiraleches de cristal con bulbo de hule	Pieza
4814	25400493	Tiras de fluoracina (uso oftalmologico)	Pieza
4815	25400494	Tiras de lija para pulir restauraciones	Pieza
4816	25400495	Tiras reactivas para la determinacion de glucosa en la sangre	Pieza
4817	25400496	Toallas para gineco obstetricia	Pieza
4818	25400497	Tornillo de compresion para tornillo de traccion	Pieza
4819	25400498	Tornillos de acero inoxidable para cirugia maxilofacial	Pieza
4820	25400499	Tornillos de schanz	Pieza
4821	25400500	Tornillos de titanio puro para cirugia maxilofacial	Pieza
4822	25400501	Tornillos de traccion	Pieza
4823	25400502	Tornillos para hueso cortical	Pieza
4824	25400503	Tornillos para hueso cortical - autoroscante	Pieza
4825	25400504	Tornillos para hueso esponjoso	Pieza
4826	25400505	Torunda algodon	Pieza
4827	25400506	Torundero	Pieza
4828	25400507	Tripie matraz	Pieza
4829	25400508	Tripie mechero	Pieza
4830	25400509	Tuberia de circulacion extracorporea para oxigenador	Pieza
4831	25400510	Tubo aspirador/irrigador (conico)	Pieza
4832	25400511	Tubo aspirador/irrigador (doble efecto)	Pieza
4833	25400512	Tubo aspirador/irrigador (hemisferico)	Pieza
4834	25400513	Tubo de extension de polivinilo	Pieza
4835	25400514	Tubo de latex color ambar para torniquete	Pieza
4836	25400515	Tubo de silastic	Pieza
4837	25400516	Tubo de vidrio refractario para dacriosistorrinostomia	Pieza
4838	25400517	Tubo endotraqueal con globo y con balon y conector opaco	Pieza
4839	25400518	Tubo endotraqueal de plastico	Pieza
4840	25400519	Tubo endotraqueal sin globo de elastomero de silicon	Pieza
4841	25400520	Tubo flexible de plastico para espirometria	Pieza
4842	25400521	Tubo flexible de polivinilo	Pieza
4843	25400522	Tubo para aspirador de hule latex	Pieza
4844	25400523	Tubo para canalizacion de latex (natural)	Pieza
4845	25400524	Tuerca para tornillo cortical	Pieza
4846	25400525	Vaina liberadora para sistema de cierre de conducto	Pieza
4847	25400526	Vainas protectoras para clavo steinmann	Pieza
4848	25400527	Valvula abdominal	Pieza
4849	25400528	Valvula aspiracion y expiracion	Pieza
4850	25400529	Valvula control fluometro	Pieza
4851	25400530	Valvula dosificacion oxigeno (anestesia)	Pieza
4852	25400531	Valvula intracardiaca mecanica	Pieza
4853	25400532	Valvula irrigacion	Pieza
4854	25400533	Valvula para derivacion de liquido cefalorraquideo	Pieza
4855	25400534	Valvula seguridad (equipo medico)	Pieza
4856	25400535	Varilla vidrio	Pieza
4857	25400536	Vaselina liquida	Litro
4858	25400537	Vaso para medicamentos	Pieza
4859	25400538	Vaso para medicamentos de vidrio	Pieza
4860	25400539	Venda	Pieza
4861	25400540	Venda enyesada	Pieza
4862	25400541	Vidrio optico	Pieza
4863	25400542	Yeso piedra azul	Pieza
4864	25400543	Yeso piedra blanco (para ortodoncia)	Pieza
4865	25400544	Accesorio dental	Pieza
4866	25400545	Aceite cuidado personal	Pieza
4867	25400547	Aceite neutro	Pieza
4868	25400548	Aceite para instrumental medico	Pieza
4869	25400549	Adhesivos medicos	Pieza
4870	25400550	Aditamento para nebulizador	Pieza
4871	25400551	Aerosol para citologia	Pieza
4872	25400552	Agua de colonia	Pieza
4873	25400553	Agua para raquea	Pieza
4874	25400554	Agujas	Pieza
4875	25400555	Alambre para hueso	Pieza
4876	25400556	Albumina	Pieza
4877	25400557	Aldosterona	Pieza
4878	25400558	Alergenico	Pieza
4879	25400559	Alfileres entomologicos	Pieza
4880	25400560	Almohadilla medica	Pieza
4881	25400561	Ampula	Pieza
4882	25400562	Anclas quirurgicas	Pieza
4883	25400563	Angiotensina	Pieza
4884	25400564	Anguladas	Pieza
4885	25400565	Antifaz	Pieza
4886	25400566	Aparato de alargamiento oseo	Pieza
4887	25400567	Aproximador	Pieza
4888	25400568	Aro para rehabilitacion	Pieza
4889	25400569	Asas (instrumento cientifico)	Pieza
4890	25400570	Audiometro	Pieza
4891	25400571	Balon para angiografia	Pieza
4892	25400572	Bandeja	Pieza
4893	25400573	Bolsa balon	Pieza
4894	25400574	Bomba de infusion	Pieza
4895	25400575	Boquilla desechable	Pieza
4896	25400576	Botafresa dental	Pieza
4897	25400577	Botiquin medico	Pieza
4898	25400578	Clavo para humero	Pieza
4899	25400579	Collarin cervical	Pieza
4900	25400580	Escala analoga del dolor (regleta graduada)	Pieza
4901	25400581	Escala de sintesis (regleta graduada)	Pieza
4902	25400582	Extension medica	Pieza
4903	25400583	Glicerina	Pieza
4904	25400584	Injerto	Pieza
4905	25400585	Insumo dental	Pieza
4906	25400586	Latiguillos	Pieza
4907	25400587	Ligaduras	Pieza
4908	25400588	Periostotomo	Pieza
4909	25400589	Placa	Pieza
4910	25400590	Polisomnografo	Pieza
4911	25400591	Prelavador	Pieza
4912	25400592	Ropa hospitalaria	Pieza
4913	25400593	Sonda (medica)	Pieza
4914	25400594	Suero (medico)	Pieza
4915	25400595	Tapa bocas	Pieza
4916	25400596	Tiranervios	Pieza
4917	25400597	Tornillo quirurgico	Pieza
4918	25400598	Gel (medico quirurgico)	Pieza
4919	25400599	Tiras reactivas	Pieza
4920	25400600	Alcohol	Pieza
4921	25400601	Capsulas vacias	Pieza
4922	25400602	Insumo para cuidad de heridas	Pieza
4923	25400603	Insumo para esterilizacion	Pieza
4924	25400604	Dona de gel	Pieza
4925	25400605	Insumo quirurgico	Pieza
4926	25400606	Insumo para laringoscopio	Pieza
4927	25400607	Insumo para monitoreo de constantes vitales	Pieza
4928	25400608	Trocar de puncion	Pieza
4929	25400609	Implante coclear	Pieza
4930	25400610	Instrumental para craneostomia	Pieza
4931	25400611	Insumo para terapia respiratoria	Pieza
4932	25400612	Sabana termica	Pieza
4933	25400613	Injerto oseo	Pieza
4934	25400614	Solucion intra-articular	Pieza
4935	2550	Materiales, accesorios y suministros de laboratorio	
4936	25501	Materiales, accesorios y suministros de laboratorio	
4937	25500001	Aparato de boyle mariot	Pieza
4938	25500002	Aparato para demostrar la conservacion de la energia	Pieza
4939	25500003	Aparato para la demostracion de los momentos	Pieza
4940	25500004	Caja madera muestras agua	Pieza
4941	25500005	Caja petri	Pieza
4942	25500006	Capsula porcelana	Pieza
4943	25500007	Cargador de dosimetros	Pieza
4944	25500008	Cono revestimiento	Pieza
4945	25500009	Crisol	Pieza
4946	25500010	Cristal refractario (laboratorio)	Pieza
4947	25500011	Cubeta desecho	Pieza
4948	25500012	Decantador	Pieza
4949	25500013	Deposito sustancias	Pieza
4950	25500014	Deslizador recorrido transversal (experimentos opticos)	Pieza
4951	25500015	Disco optico de hartl	Pieza
4952	25500016	Embudo separador	Pieza
4953	25500017	Espita (llave)	Pieza
4954	25500018	Frasco ambar	Pieza
4955	25500019	Frasco gotero pipeta	Pieza
4956	25500020	Hoja laringoscopio	Pieza
4957	25500021	Inhalador (recipiente)	Pieza
4958	25500022	Lente	Pieza
4959	25500023	Lente microscopio	Pieza
4960	25500024	Matraz	Pieza
4961	25500025	Mechero	Pieza
4962	25500026	Micropipetas	Pieza
4963	25500027	Mortero de laboratorio	Pieza
4964	25500028	Navecillas combustion	Pieza
4965	25500029	Pabellon	Pieza
4966	25500030	Pilas voltaicas	Pieza
4967	25500031	Pipeta	Pieza
4968	25500032	Plato de acero inoxidable para concentracion	Pieza
4969	25500033	Porta delantales y guantes	Pieza
4970	25500034	Porta matraz dental	Pieza
4971	25500035	Porta objetos	Pieza
4972	25500036	Prisma reflexion	Pieza
4973	25500037	Probeta	Pieza
4974	25500038	Riel clips	Pieza
4975	25500039	Sonda	Pieza
4976	25500040	Sonda para contador geiger	Pieza
4977	25500041	Soporte adaptador horizontal vertical (experimentos opticos)	Pieza
4978	25500042	Soporte cristal tarjetas (experimentos opticos)	Pieza
4979	25500043	Soporte para laboratorio	Pieza
4980	25500044	Soporte porta placas de pared	Pieza
4981	25500045	Tirapuentes	Pieza
4982	25500046	Tubo corrugado	Pieza
4983	25500047	Tubo ensayo	Pieza
4984	25500048	Tubo muestrador	Pieza
4985	25500049	Tubo rayos granode	Pieza
4986	25500050	Tubo succion	Pieza
4987	25500051	Tubos capilares	Pieza
4988	25500052	Vaso precipitado	Pieza
4989	25500053	Vasos comunicantes	Pieza
4990	25500054	Vidrio cobalto	Pieza
4991	25500055	Vidrio de cristal de cuarzo	Pieza
4992	25500056	Vidrio reloj	Pieza
4993	25500057	Tapa para crisol de todo tipo de material	Pieza
4994	25500058	Base soporte de matraces	Pieza
4995	25500059	Aceite de inmersion	Litro
4996	25500060	Aceite de silicon para cirugia	Litro
4997	25500061	Acrodiscos	Pieza
4998	25500062	Aditamento para toma de radiografias	Pieza
4999	25500063	Agua peptonada	Pieza
5000	25500064	Amortiguador para ensayo	Pieza
5001	25500065	Bandeja	Pieza
5002	25500066	Colorante para microbiologia	Pieza
5003	25500067	Marcador de peso molecular	Pieza
5004	25500068	Piseta	Pieza
5005	25500069	Pistilo	Pieza
5006	25500070	Piston	Pieza
5007	25500071	Placa	Pieza
5008	25500072	Recipiente	Pieza
5009	25500073	Ventana de bromuro de plata	Pieza
5010	25500074	Ventana de cloruro de sodio	Pieza
5011	25500075	Desecador de polipropileno	Pieza
5012	25500076	Embudo bunsen	Pieza
5013	25500077	Frasco	Pieza
5014	25500078	Gel refrigerante	Pieza
5015	25500079	Pañuelos antiestaticos	Pieza
5016	25500080	Pinzas	Pieza
5017	25500081	Lana de cuarzo	Pieza
5018	25500082	Filtro para tubos de reactivos	Pieza
5019	25500083	Polimero (PTFE, Septa, Ferrules)	Pieza
5020	25500084	Cinta de carbon	Pieza
5021	25500085	Hamster	Pieza
5022	25500086	Electrodo para iones especificos	Pieza
5023	25500087	Electrodo de referencia	Pieza
5024	25500088	Reactivos quimicos para uso de laboratorio de medicion	Pieza
5025	25500089	Material de vidrio para uso en laboratorio de medicion	Pieza
5026	25500090	Material de plastico para uso en laboratorio de medicion	Pieza
5027	25500091	Material de madera para uso en laboratorio de medicion	Pieza
5028	25500092	Material metalico para uso en laboratorio de medicion	Pieza
5029	25500093	Material ceramico para uso en laboratorio de medicion	Pieza
5030	25500094	Sensor optico	Pieza
5031	25500095	Puntas para micropipeta	Pieza
5032	25500096	Termometro	Pieza
5033	25500097	Escobillon para laboratorio	Pieza
5034	25500098	Papel filtro	Pieza
5035	25500099	Medios de contraste	Pieza
5036	25500100	Sulfato de bario	Pieza
5037	25500101	Cajas plastificadas	Pieza
5038	25500102	Equipo para toma multiple	Pieza
5039	25500103	Papel parafilm	Pieza
5040	25500104	Lapiz punta diamante	Pieza
5041	25500105	Aguja para toma multiple	Pieza
5042	25500106	Cuchillas para microtomo	Pieza
5043	25500107	Cronometro	Pieza
5044	25500108	Rejilla de asbesto	Pieza
5045	25500109	Cubrehematimetro	Pieza
5046	25500110	Hierbas, arbustos o arboles para experimentacion	Pieza
5047	25500111	Rata para experimentacion	Pieza
5048	25500112	Raton para experimentacion	Pieza
5049	25500113	Conejo para experimentacion	Pieza
5050	25500114	Cama sanitaria para animales de laboratorio	Pieza
5051	25500115	Papel para germinacion de semillas	Pieza
5052	25500116	Peces para experimentacion	Pieza
5053	25500117	Cerdo para experimentacion	Pieza
5054	25500118	GPS para rastreo	Pieza
5055	25500119	Seres biologicos (restos mortales)	Pieza
5056	2560	Fibras sinteticas, hules, plasticos y derivados	
5057	25601	Fibras sinteticas, hules, plasticos y derivados	
5058	2590	Otros productos quimicos	
5059	25901	Otros productos quimicos	
5060	25900001	Extracto alergenico	Pieza
5061	25900002	Extracto de levadura	Pieza
5062	25900003	Formaldehido	Pieza
5063	25900004	Formamida	Pieza
5064	25900005	Formol	Pieza
5065	25900006	Gadolinio	Pieza
5066	25900007	Hematoxilina	Pieza
5067	25900008	Hemocolorante	Pieza
5068	25900009	Hipoclorito	Pieza
5069	25900010	Histamina	Pieza
5070	25900011	Sustancias en forma solida para uso en laboratorio de medicion	Pieza
5071	25900012	Sustancias en forma liquida para uso en laboratorio de medicion	Pieza
5072	25900013	Sustancias en forma gaseosa para uso en laboratorio de medicion	Pieza
5073	25900014	Plata coloidal	Pieza
5074	25900015	Hidroxido de calcio	Pieza
5075	25900016	Sales para tratamiento termico	Pieza
5076	2600	Combustibles, lubricantes y aditivos	
5077	2610	Combustibles, lubricantes y aditivos	
5078	26101	Combustibles, lubricantes y aditivos para vehiculos terrestres, aereos, maritimos, lacustres y fluviales destinados a la ejecucion de programas de seguridad publica y nacional	
5079	26102	Combustibles, lubricantes y aditivos para vehiculos terrestres, aereos, maritimos, lacustres y fluviales destinados a servicios publicos y la operacion de programas publicos	
5080	26100002	Aceite combustible	Litro
5081	26100003	Aceite lubricante	Litro
5082	26100004	Aditivo	Litro
5083	26100007	Gas avion	Litro
5084	26100009	Gas licuado	Litro
5085	26100011	Gas nafta	Litro
5086	26100012	Gasoleo diesel	Litro
5087	26100013	Gasolina	Litro
5088	26100014	Grasas lubricantes	Litro
5089	26100015	Keroseno	Litro
5090	26100016	Lubricante fluido	Litro
5091	26100017	Lubricantes sinteticos	Litro
5092	26100018	Lubricantes solidos	Litro
5093	26100019	Petroleo diafano	Litro
5094	26100020	Tractomex	Litro
5095	26100021	Turbosina	Litro
5096	26100022	Gas natural	Litro
5097	26100023	Petroleo crudo	Litro
5098	26103	Combustibles, lubricantes y aditivos para vehiculos terrestres, aereos, maritimos, lacustres y fluviales destinados a servicios administrativos	
5099	26100050	Anticongelante	Litro
5100	26104	Combustibles, lubricantes y aditivos para vehiculos terrestres, aereos, maritimos, lacustres y fluviales asignados a servidores publicos	
5101	26100060	Gasolina	Litro
5102	26105	Combustibles, lubricantes y aditivos para maquinaria, equipo de produccion y servicios administrativos	
5103	26100001	Aceite aislante	Litro
5104	26100005	Gas acetileno	Litro
5105	26100006	Gas argon	Litro
5106	26100008	Gas freon	Litro
5107	26100010	Gas LP	Litro
5108	26100030	Diesel	Litro
5109	26106	PIDIREGAS cargos variables	
5110	26107	Combustibles nacionales para plantas productivas	
5111	26108	Combustibles de importacion para plantas productivas	
5112	2620	Carbon y sus derivados	
5113	26200001	Carbon de piedra	Kilogramo
5114	26200002	Coque de carbon	Kilogramo
5115	26200003	Coque de petroleo	Kilogramo
5116	2700	Vestuario, blancos, prendas de proteccion y articulos deportivos	
5117	2710	Vestuario y uniformes	
5118	27101	Vestuario y uniformes	
5119	27100001	Abanico (atavio civil militar o religioso)	Pieza
5120	27100002	Abrigos	Pieza
5121	27100003	Ajorca (atavio civil militar o religioso)	Pieza
5122	27100004	Alba (atavio civil militar o religioso)	Pieza
5123	27100005	Alfiler (atavio civil militar o religioso)	Pieza
5124	27100006	Alzacuello (atavio civil militar o religioso)	Pieza
5125	27100007	Amito (atavio civil militar o religioso)	Pieza
5126	27100008	Anillo (atavio civil militar o religioso)	Pieza
5127	27100009	Arete (atavio civil militar o religioso)	Pieza
5128	27100010	Armadura (atavio civil militar o religioso)	Pieza
5129	27100011	Arnes (atavio civil militar o religioso)	Pieza
5130	27100012	Articulos de guarnicioneria	Pieza
5131	27100013	Articulos troquelados (placas, escudos, etc.	Pieza
5132	27100014	Banda frontal (atavio civil militar o religioso)	Pieza
5133	27100015	Barbiquejo (atavio civil militar o religioso)	Pieza
5134	27100016	Barra ceremonial (atavio civil militar o religioso)	Pieza
5135	27100017	Baston d/mando (atavio civil militar o religioso)	Pieza
5136	27100018	Baston o baculo (atavio civil militar o religioso)	Pieza
5137	27100019	Batas	Pieza
5138	27100020	Bicornio (atavio civil militar o religioso)	Pieza
5139	27100021	Birrete (atavio civil militar o religioso)	Pieza
5140	27100022	Blusas	Pieza
5141	27100023	Boina (atavio civil militar o religioso)	Pieza
5142	27100024	Bolsa d/corporales (atavio civil militar o religioso)	Pieza
5143	27100025	Bolsa d/mano (atavio civil militar o religioso)	Pieza
5144	27100026	Bonete (atavio civil militar o religioso)	Pieza
5145	27100027	Bota (atavio civil militar o religioso)	Pieza
5146	27100028	Boton (atavio civil militar o religioso)	Pieza
5147	27100029	Braguero o maxtlatl (atavio civil militar o religioso)	Pieza
5148	27100030	Brazalete (atavio civil militar o religioso)	Pieza
5149	27100031	Broche (atavio civil militar o religioso)	Pieza
5150	27100032	Broquel (atavio civil militar o religioso)	Pieza
5151	27100033	Calabaza (atavio civil militar o religioso)	Pieza
5152	27100034	Calcetas	Pieza
5153	27100035	Calcetines	Pieza
5154	27100036	Calzado de tela	Pieza
5155	27100037	Calzado de vestir	Pieza
5156	27100038	Camisas para caballero	Pieza
5157	27100039	Camisones y pijamas	Pieza
5158	27100040	Canana (cinturon) (atavio civil militar o religioso)	Pieza
5159	27100041	Capa (atavio civil militar o religioso)	Pieza
5160	27100042	Capa pluvial (atavio civil militar o religioso)	Pieza
5161	27100043	Capota (atavio civil militar o religioso)	Pieza
5162	27100044	Capucha (atavio civil militar o religioso)	Pieza
5163	27100045	Caracol (atavio civil militar o religioso)	Pieza
5164	27100046	Carpetas	Pieza
5165	27100047	Cartera (atavio civil militar o religioso)	Pieza
5166	27100048	Casaca (atavio civil militar o religioso)	Pieza
5167	27100049	Casaquin (atavio civil militar o religioso)	Pieza
5168	27100050	Cascabel (atavio civil militar o religioso)	Pieza
5169	27100051	Casco (atavio civil militar o religioso)	Pieza
5170	27100052	Casulla (atavio civil militar o religioso)	Pieza
5171	27100053	Cetro (atavio civil militar o religioso)	Pieza
5172	27100054	Chaleco (atavio civil militar o religioso)	Pieza
5173	27100055	Chaqueta (atavio civil militar o religioso)	Pieza
5174	27100056	Charretera (atavio civil militar o religioso)	Pieza
5175	27100057	Cingulo (atavio civil militar o religioso)	Pieza
5176	27100058	Cinturon (atavio civil militar o religioso)	Pieza
5177	27100059	Cofia (atavio civil militar o religioso)	Pieza
5178	27100060	Colgante o pendiente (atavio civil militar o religioso)	Pieza
5179	27100061	Collar o gargantilla (atavio civil militar o religioso)	Pieza
5180	27100062	Colmillo o diente de animal (atavio civil militar o religioso)	Pieza
5181	27100063	Concha (no de caracol) (atavio civil militar o religioso)	Pieza
5182	27100064	Coraza (militar) (atavio civil militar o religioso)	Pieza
5183	27100065	Corporales (atavio civil militar o religioso)	Pieza
5184	27100066	Cota (atavio civil militar o religioso)	Pieza
5185	27100067	Dalmatica (atavio civil militar o religioso)	Pieza
5186	27100068	Delantal (atavio civil militar o religioso)	Pieza
5187	27100069	Diadema (atavio civil militar o religioso)	Pieza
5188	27100070	Dije (atavio civil militar o religioso)	Pieza
5189	27100071	Empaques de cuero y piel	Pieza
5190	27100072	Esclavina (atavio civil militar o religioso)	Pieza
5191	27100073	Espejuelos, lentes , anteojos (atavio civil militar o religioso)	Pieza
5192	27100074	Espuelas y acicate (atavio civil militar o religioso)	Pieza
5193	27100075	Estola (atavio civil militar o religioso)	Pieza
5194	27100076	Faja-banda o ceñidor (atavio civil militar o religioso)	Pieza
5195	27100077	Faldas	Pieza
5196	27100078	Faldilla (atavio civil militar o religioso)	Pieza
5197	56300129	Tolva	Pieza
5198	27100079	Fez (gorro) (atavio civil militar o religioso)	Pieza
5199	27100080	Filipinas	Pieza
5200	27100081	Fistol o fija corbata (atavio civil militar o religioso)	Pieza
5201	27100082	Frac (atavio civil militar o religioso)	Pieza
5202	27100083	Gorro (atavio civil militar o religioso)	Pieza
5203	27100084	Greguescos (atavio civil militar o religioso)	Pieza
5204	27100085	Guadameci	Pieza
5205	27100086	Guante (atavio civil militar o religioso)	Pieza
5206	27100087	Guantelete (atavio civil militar o religioso)	Pieza
5207	27200014	Impermeable	Pieza
5208	27100088	Hebilla (atavio civil militar o religioso)	Pieza
5209	27100089	Huipil (atavio civil militar o religioso)	Pieza
5210	27100090	Humeral (atavio civil militar o religioso)	Pieza
5211	27100091	Infulas (atavio civil militar o religioso)	Pieza
5212	27100092	Jubon (atavio civil militar o religioso)	Pieza
5213	27100093	Latigo	Pieza
5214	27100094	Levita (atavio civil militar o religioso)	Pieza
5215	27100095	Manipulo (atavio civil militar o religioso)	Pieza
5216	27100096	Mascara (atavio civil militar o religioso)	Pieza
5217	27100097	Mecapal (atavio civil militar o religioso)	Pieza
5218	27100098	Medias	Pieza
5219	27100099	Medio queso (atavio civil militar o religioso)	Pieza
5220	27100100	Mitra (atavio civil militar o religioso)	Pieza
5221	27100101	Moises (porta bebe)	Pieza
5222	27100102	Morral (atavio civil militar o religioso)	Pieza
5223	27100103	Morrion (atavio civil militar o religioso)	Pieza
5224	27100104	Muñequera (atavio civil militar o religioso)	Pieza
5225	27100105	Nariguera (atavio civil militar o religioso)	Pieza
5226	27100106	Orejera (atavio civil militar o religioso)	Pieza
5227	27100107	Palio (atavio civil militar o religioso)	Pieza
5228	27100108	Pantalones para caballero	Pieza
5229	27100109	Pantalones para dama	Pieza
5230	27100110	Pañal desechable	Pieza
5231	27100111	Pañoleta (atavio civil militar o religioso)	Pieza
5232	27100112	Pañuelo (atavio civil militar o religioso)	Pieza
5233	27100113	Parasol (atavio civil militar o religioso)	Pieza
5234	27100114	Pectoral (atavio civil militar o religioso)	Pieza
5235	27100115	Peineta (atavio civil militar o religioso)	Pieza
5236	27100116	Penacho (atavio civil militar o religioso)	Pieza
5237	27100117	Peto ixcahuipil (atavio civil militar o religioso)	Pieza
5238	27100118	Pipa (atavio civil militar o religioso)	Pieza
5239	27100119	Polainas (atavio civil militar o religioso)	Pieza
5240	27100120	Portaestandarte (atavio civil militar o religioso)	Pieza
5241	27100121	Portamonedas (atavio civil militar o religioso)	Pieza
5242	27100122	Prendedor o camafeo (atavio civil militar o religioso)	Pieza
5243	27100123	Probador de calzado	Pieza
5244	27100124	Productos de marroquinaria y estucheria	Pieza
5245	27100125	Productos de talabarteria	Pieza
5246	27100126	Pulsera (atavio civil militar o religioso)	Pieza
5247	27100127	Puños (atavio civil militar o religioso)	Pieza
5248	27100128	Quechquemetl (atavio civil militar o religioso)	Pieza
5249	27100129	Quepis (atavio civil militar o religioso)	Pieza
5250	27100130	Rebozo (atavio civil militar o religioso)	Pieza
5251	27100131	Relicario o guarda pelo (atavio civil militar o religioso)	Pieza
5252	27100132	Reloj pulsera, bolsillo  o broche (atavio civil militar o religioso)	Pieza
5253	27100133	Rodillera (atavio civil militar o religioso)	Pieza
5254	27100134	Ropa interior	Pieza
5255	27100135	Roquete (atavio civil militar o religioso)	Pieza
5256	27100136	Sandalias o huaraches (atavio civil militar o religioso)	Pieza
5257	27100137	Sarape o cobija (atavio civil militar o religioso)	Pieza
5258	27100139	Sobrepelliz (atavio civil militar o religioso)	Pieza
5259	27100140	Solideo (atavio civil militar o religioso)	Pieza
5260	27100141	Sombrero (atavio civil militar o religioso)	Pieza
5261	27100142	Sotana (atavio civil militar o religioso)	Pieza
5262	27100143	Tapon d/orejera (atavio civil militar o religioso)	Pieza
5263	27100144	Tocado (atavio civil militar o religioso)	Pieza
5264	27100145	Traje regional (atavio civil militar o religioso)	Pieza
5265	27100146	Trajes para caballero	Pieza
5266	27100147	Tricornio (atavio civil militar o religioso)	Pieza
5267	27100148	Tunica (atavio civil militar o religioso)	Pieza
5268	27100149	Turbante (atavio civil militar o religioso)	Pieza
5269	27100150	Uniformes de trabajo	Pieza
5270	27100151	Uniformes deportivos	Pieza
5271	27100152	Uniformes escolares	Pieza
5272	27100153	Uniformes hospitalarios	Pieza
5273	27100154	Uniformes militares	Pieza
5274	27100155	Valona (atavio civil militar o religioso)	Pieza
5275	27100156	Vestidos	Pieza
5276	27100157	Yahual (atavio civil militar o religioso)	Pieza
5277	27100158	Yelmo (atavio civil militar o religioso)	Pieza
5278	27100159	Insignia (atavio civil militar o religioso)	Pieza
5279	27100160	Playera	Pieza
5280	27100161	Saco	Pieza
5281	27100162	Sudadera	Pieza
5282	27100163	Sueter	Pieza
5283	27100164	Trajes para dama	Pieza
5284	27100165	Corbata	Pieza
5285	27100166	Bandera	Pieza
5286	27100167	Banderin	Pieza
5287	27100168	Gorras/cachuchas	Pieza
5288	27100169	Cierre	Pieza
5289	27100170	Chapeton	Pieza
5290	2720	Prendas de seguridad y proteccion personal	
5291	27201	Prendas de proteccion personal	
5292	27200001	Anteojos de seguridad	Pieza
5293	27200002	Botas de seguridad	Pieza
5294	27200003	Calzado seguridad	Pieza
5295	27200004	Camilla (tabla)	Pieza
5296	27200005	Capsula de emanacion de radon (realiza mediciones de radiacion)	Pieza
5297	27200006	Careta soldador	Pieza
5298	27200007	Cartucho mascarilla	Pieza
5299	27200008	Casco seguridad	Pieza
5300	27200009	Cinturon de seguridad	Pieza
5301	27200010	Cristal caretas y gafas seguridad	Pieza
5302	27200011	Entradas giratorias (para acceso)	Pieza
5303	27200012	Guantes de hule	Pieza
5304	27200013	Guantes de seguridad	Pieza
5305	27200015	Mandil (peto)	Pieza
5306	27200016	Manga emplomada	Pieza
5307	27200017	Manga proteccion soldador	Pieza
5308	27200018	Mascarilla seguridad contra polvo o gas	Pieza
5309	27200019	Orejera protectora contra ruidos	Pieza
5310	27200020	Uniforme, traje de seguridad y mantenimiento	Pieza
5311	27200021	Arnes de seguridad amortiguador	Pieza
5312	27200022	Cuerda o cable de seguridad (linea de vida) con ganchos y candado	Pieza
5313	27200023	Gafas protectoras (goggles)	Pieza
5314	27200024	Ropa quirurgica	Pieza
5315	27200025	Equipo para entrenamiento canino	Pieza
5316	27200026	Forro para casco antifragmento	Pieza
5317	2730	Articulos deportivos	
5318	27301	Articulos deportivos	
5319	27300001	Anzuelo	Pieza
5320	27300002	Arco	Pieza
5321	27300003	Argollas (gimnasia)	Pieza
5322	27300004	Arnes paracaidas	Pieza
5323	27300005	Arpon	Pieza
5324	27300006	Articulos deportivos de hule	Pieza
5325	27300007	Asador carnes	Pieza
5326	27300008	Ascensor jumar	Pieza
5327	27300010	Bala bronce	Pieza
5328	27300011	Balon futbol (americano o soccer)	Pieza
5329	27300012	Balon voleibol	Pieza
5330	27300013	Balon waterpolo	Pieza
5331	27300014	Banco salida natacion	Pieza
5332	27300015	Barra salto altura	Pieza
5333	27300016	Barras componentes del gimnasio universal	Pieza
5334	27300017	Base arranque pista	Pieza
5335	27300018	Baston cromado	Pieza
5336	27300019	Baston hockey	Pieza
5337	27300020	Bate beisbol	Pieza
5338	27300021	Bola boliche y billar	Pieza
5339	27300022	Bola sorteo	Pieza
5340	27300023	Bolsa lona de dormir	Pieza
5341	27300024	Bolsa triangulo doble	Pieza
5342	27300025	Botador con cinco resortes	Pieza
5343	27300026	Calzado deportivo	Pieza
5344	27300027	Canguro (portabebe)	Pieza
5345	27300028	Cantimplora	Pieza
5346	27300029	Caña de pescar	Pieza
5347	27300030	Careta deportiva	Pieza
5348	27300031	Casco deportivo	Pieza
5349	27300032	Catre	Pieza
5350	27300033	Chaleco salvavidas	Pieza
5351	27300034	Chapoteadero (alberca portatil)	Pieza
5352	27300035	Cinturon alpinista	Pieza
5353	27300036	Colchoneta gimnasia	Pieza
5354	27300037	Contador vueltas	Pieza
5355	27300038	Costal box	Pieza
5356	27300039	Cubilete	Pieza
5357	27300040	Disco lanzamiento	Pieza
5358	27300041	Escafandra	Pieza
5359	27300042	Espinillera, rodillera y demas protectores	Pieza
5360	27300043	Flecha	Pieza
5361	27300044	Frenos de ocho	Pieza
5362	27300046	Guante deportivo	Pieza
5363	27300047	Hamaca	Pieza
5364	27300048	Jabalina	Pieza
5365	27300049	Juego patines	Pieza
5366	27300050	Juego pelotas (tenis, ping-pong, beisbol, etc.)	Pieza
5367	27300051	Lampara campaña (gas, gasolina, petroleo, bateria)	Pieza
5368	27300052	Lonchera	Pieza
5369	27300053	Mancuerna	Pieza
5370	27300054	Marimba descenso lento	Pieza
5371	27300055	Minitramp	Pieza
5372	27300056	Mochila de excursion	Pieza
5373	27300057	Mochila paracaidas	Pieza
5374	27300058	Mosqueton	Pieza
5375	27300059	Paraguas (quitasol, sombrilla)	Pieza
5376	27300060	Pera box (fija y loca)	Pieza
5377	27300061	Pertiga (salto de altura)	Pieza
5378	27300062	Petaca	Pieza
5379	27300063	Piolet	Pieza
5380	27300064	Productos de cuero para deportes	Pieza
5381	27300065	Raqueta	Pieza
5382	27300066	Red	Pieza
5383	27300067	Remo	Pieza
5384	27300068	Resortera	Pieza
5385	27300069	Rompecabezas (juego de)	Pieza
5386	27300070	Señuelo	Pieza
5387	27300071	Silla tijera	Pieza
5388	27300072	Skys	Pieza
5389	27300073	Spikes (tenis con clavos)	Pieza
5390	27300074	Tacos de billar	Pieza
5391	27300075	Talquero mesa boliche	Pieza
5392	27300076	Trompa esfera sorteo (accesorio)	Pieza
5393	27300077	Tubo esfera sorteo (accesorio)	Pieza
5394	27300078	Visor	Pieza
5395	27300079	Zapato deportivo y aletas	Pieza
5396	27300080	Almohadillas para bases de beisbol	Pieza
5397	27300081	Antena para redes (accesorio)	Pieza
5398	27300082	Bicicletas elipticas	Pieza
5399	27300083	Caratulas para tiro con arco	Pieza
5400	27300084	Domi para karate	Pieza
5401	27300085	Gafas protectoras (goggles)	Pieza
5402	27300086	Gorra (natacion)	Pieza
5403	27300087	Manopla	Pieza
5404	27300088	Medallas	Pieza
5405	27300089	Pelota	Pieza
5406	27300090	Balon	Pieza
5407	27300091	Arnes doble para buceo	Pieza
5408	27300092	Arnes porta plato para buceo	Pieza
5409	27300093	Bandas dobles para tanques de buceo	Pieza
5410	27300094	Boquilla de oxigeno para buceo	Pieza
5411	27300095	Computadora tipo pulsera para buceo	Pieza
5412	27300096	Linterna subacuatica	Pieza
5413	27300097	Plato para tanques dobles de buceo	Pieza
5414	27300098	Porta arnes para buceo	Pieza
5415	27300099	Valvula multiple para tanque de buceo	Pieza
5416	27300100	Ventilador para desplazamiento en  buceo	Pieza
5417	27300101	Cronometro	Pieza
5418	27300102	Trofeos	Pieza
5419	27300103	Cuerda	Pieza
5420	27300104	Contador manual de personas	Pieza
5421	27300105	Placas indicadoras	Pieza
5422	27300106	Accesorios para entrenamiento(pera de box, base para pera, etc.)	Pieza
5423	27300107	Silbato	Pieza
5424	27300108	Paracaidas	Pieza
5425	27300109	Aro salvavidas	Pieza
5426	27300110	Mochila hidratante	Pieza
5427	2740	Productos textiles	
5428	27401	Productos textiles	
5429	27400001	Jerga	Metro Cuadrado
5430	27400002	Franela	Metro Cuadrado
5431	27400003	Manta	Metro Cuadrado
5432	27400004	Lino	Metro Cuadrado
5433	27400005	Seda	Metro Cuadrado
5434	27400006	Algodon	Metro Cuadrado
5435	27400007	Ixtle	Metro Cuadrado
5436	27400008	Henequen	Metro Cuadrado
5437	2750	Blancos y otros productos textiles, excepto prendas de vestir	
5438	27501	Blancos y otros productos textiles, excepto prendas de vestir	
5439	27500001	Almohadas y cojines	Pieza
5440	27500002	Cintas, agujetas, listones	Pieza
5441	27500003	Cobertores	Pieza
5442	27500004	Cojin almohada	Pieza
5443	27500005	Colchas	Pieza
5444	27500006	Colchones	Pieza
5445	27500007	Cortinas para baño	Pieza
5446	27500008	Fundas	Pieza
5447	27500009	Juegos para baño	Pieza
5448	27500010	Manteles	Pieza
5449	27500011	Mantilla calentamiento	Pieza
5450	27500012	Sabanas	Pieza
5451	27500013	Servilletas	Pieza
5452	27500014	Tapete para baño	Pieza
5453	27500015	Toallas	Pieza
5454	2800	Materiales y suministros para seguridad	
5455	2810	Sustancias y materiales explosivos	
5456	28101	Sustancias y materiales explosivos	
5457	28100001	Amatol (substancias y productos explosivos)	Litro
5458	28100002	Cordon detonante economico (substancias y productos explosivos)	Litro
5459	28100003	Cordon detonante reforzado (substancias y productos explosivos)	Litro
5460	28100004	Dinamita gelatinada al 400 (substancias y productos explosivos)	Litro
5461	28100005	Dinamita gelatinada al 600 (substancias y productos explosivos)	Litro
5462	28100006	Explosivos preparados (substancias y productos explosivos)	Litro
5463	28100007	Fulminante de mercurio (substancias y productos explosivos)	Litro
5464	28100008	Fulminante de plomo (substancias y productos explosivos)	Litro
5465	28100009	Polvora negra (substancias y productos explosivos)	Litro
5466	28100010	Polvora para minas (substancias y productos explosivos)	Litro
5467	28100011	Polvora sin humo (substancias y productos explosivos)	Litro
5468	28100012	Tetril (substancias y productos explosivos)	Litro
5469	28100013	Trinito (substancias y productos explosivos)	Litro
5470	28100014	Fulminante (substancias y productos explosivos)	Pieza
5471	2820	Materiales de seguridad publica	
5472	28201	Materiales de seguridad publica	
5473	28200001	Alza (accesorio militar)	Pieza
5474	28200002	Asper gas lacrimogeno (accesorio militar)	Pieza
5475	28200003	Atalaje (accesorio militar)	Pieza
5476	28200004	Balas (accesorio militar)	Pieza
5477	28200005	Bomba aviacion (accesorio militar)	Pieza
5478	28200006	Caja manguera incendio	Pieza
5479	28200007	Capsula (accesorio militar)	Pieza
5480	28200008	Cargas profundidad (accesorio militar)	Pieza
5481	28200009	Cartucho bola de plomo (accesorio militar)	Pieza
5482	28200010	Cartucho bote de metralleta (accesorio militar)	Pieza
5483	28200011	Cartucho granada (accesorio militar)	Pieza
5484	28200012	Cartucho salva (accesorio militar)	Pieza
5485	28200013	Cerrojo (accesorio militar)	Pieza
5486	28200014	Cilindro gas polvo (accesorio militar)	Pieza
5487	28200015	Cubo (accesorio militar)	Pieza
5488	28200016	Cubre cierre (accesorio militar)	Pieza
5489	28200017	Detector incendios	Pieza
5490	28200018	Equipo contra incendio forestal	Pieza
5491	28200019	Espoleta (accesorio militar)	Pieza
5492	28200020	Esposas (accesorio militar)	Pieza
5493	28200021	Estopin (accesorio militar)	Pieza
5494	28200022	Faro buscador niebla	Pieza
5495	28200023	Flecha con mango (accesorio militar)	Pieza
5496	28200024	Fornitura (accesorio militar)	Pieza
5497	28200025	Granada de mano (accesorio militar)	Pieza
5498	28200026	Lampara intermitente	Pieza
5499	28200027	Llave cuerda registro reloj	Pieza
5500	28200028	Mano mecanica señales	Pieza
5501	28200029	Nebulizador (accesorio militar)	Pieza
5502	28200030	Petardo (accesorio militar)	Pieza
5503	28200031	Portacartuchos para arma de fuego corta o larga (accesorio militar)	Pieza
5504	28200032	Proyectil varios calibres (accesorio militar)	Pieza
5505	28200033	Reflector	Pieza
5506	28200034	Reloj caja fuerte	Pieza
5507	28200035	Rociador (incendio)	Pieza
5508	28200036	Señal portatil seguridad	Pieza
5509	28200037	Sirena	Pieza
5510	28200038	Sirena (automotriz)	Pieza
5511	28200039	Sirena reflector	Pieza
5512	28200040	Sotrozo (accesorio militar)	Pieza
5513	28200041	Torreta tipo burbuja	Pieza
5514	28200042	Voladora (accesorio militar)	Pieza
5515	28200043	Accesorios militares	Pieza
5516	28200044	Camuflaje (camoustick)	Pieza
5517	28200045	Equipo para primer respondiente	Pieza
5518	28200046	Lanzadora tactica	Pieza
5519	28200047	Adaptador para abastecimiento de lanzadora tactica	Pieza
5520	28200048	Municiones	Pieza
5521	28200049	Componentes para armamento	Pieza
5522	28200050	Baston policial	Pieza
5523	2830	Prendas de proteccion para seguridad publica y nacional	
5524	28301	Prendas de proteccion para seguridad publica y nacional	
5525	28300001	Afuste	Pieza
5526	28300002	Careta antigas con filtro para proteger contra agentes quimicos	Pieza
5527	28300003	Chaleco anti-balas	Pieza
5528	28300004	Chaleco de seguridad	Pieza
5529	28300005	Escudo	Pieza
5530	28300006	Esposas metalicas	Pieza
5531	28300007	Lentes protectores para tiro profesional	Pieza
5532	28300008	Manta antibomba	Pieza
5533	28300009	Traje antibomba	Pieza
5534	28300010	Placa balistica	Pieza
5535	28300011	Panel balistico	Pieza
5536	28300012	Codera tactica	Pieza
5537	28300013	Rodillera tactica	Pieza
5538	28300014	Fajilla policial	Pieza
5539	2900	Herramientas, refacciones y accesorios menores	
5540	2910	Herramientas menores	
5541	29101	Herramientas menores	
5542	29100001	Abocardador	Pieza
5543	29100002	Aceitera cuenta gotas con vaso	Pieza
5544	29100003	Aceitera presion	Pieza
5545	29100004	Adaptador laton	Pieza
5546	29100005	Ahorcador	Pieza
5547	29100006	Ahumador (implemento agricola)	Pieza
5548	29100007	Alicate	Pieza
5549	29100008	Anillo extraer tuberia	Pieza
5550	29100009	Apisonador manual	Pieza
5551	29100010	Aplicador de silicon	Pieza
5552	29100011	Apretador punzon (implemento agricola)	Pieza
5553	29100012	Arco calar	Pieza
5554	29100013	Arco segueta	Pieza
5555	29100014	Arreador agropecuario (implemento agricola)	Pieza
5556	29100015	Asentador navaja	Pieza
5557	29100016	Autocle con maneral, dado y extension	Pieza
5558	29100017	Avellanador	Pieza
5559	29100018	Azada	Pieza
5560	29100019	Azadon	Pieza
5561	29100020	Azuela	Pieza
5562	29100021	Baliza	Pieza
5563	29100022	Barrena perforacion	Pieza
5564	29100023	Barreta	Pieza
5565	29100024	Base tornillo	Pieza
5566	29100025	Berbiqui	Pieza
5567	29100026	Bieldo o tridente	Pieza
5568	29100027	Broquero taladro	Pieza
5569	29100028	Buril	Pieza
5570	29100029	Cable malacate	Pieza
5571	29100030	Caja herramientas	Pieza
5572	29100031	Calafateadora	Pieza
5573	29100032	Cargador manual cristales (ventosas)	Pieza
5574	29100033	Carretilla broca	Pieza
5575	29100034	Carretilla ventana	Pieza
5576	29100035	Catarina	Pieza
5577	29100036	Cautin	Pieza
5578	29100037	Cava hoyos	Pieza
5579	29100038	Chaira	Pieza
5580	29100039	Chaira parra (eslabon)	Pieza
5581	29100040	Chiflon	Pieza
5582	29100041	Cilindro de gas intercambiable (tanque)	Pieza
5583	29100042	Cincel	Pieza
5584	29100043	Cinta metrica (sastre)	Pieza
5585	29100044	Concha carretilla	Pieza
5586	29100045	Contratuercas	Pieza
5587	29100046	Cople barra perforacion	Pieza
5588	29100047	Corta vidrio	Pieza
5589	29100048	Cortador tubo	Pieza
5590	29100049	Cubre taladro lavabo	Pieza
5591	29100050	Cuchara albañil	Pieza
5592	29100051	Cuchara fundicion	Pieza
5593	29100052	Cucharilla minera	Pieza
5594	29100053	Cucharon plomo	Pieza
5595	29100054	Cuchilla	Pieza
5596	29100055	Cuchillas desconectadoras	Pieza
5597	29100056	Cuchillo y navaja mil usos	Pieza
5598	29100057	Cuenta hilos	Pieza
5599	29100058	Cuerpos tensores	Pieza
5600	29100059	Cuñas	Pieza
5601	29100060	Cuña terminal abierta	Pieza
5602	29100061	Dado (llave caja)	Pieza
5603	29100062	Dado redondo para roscas	Pieza
5604	29100063	Desarmador	Pieza
5605	29100064	Desarmador impacto	Pieza
5606	29100065	Destapador drenaje	Pieza
5607	29100066	Destorcedor	Pieza
5608	29100067	Diamante rectificador	Pieza
5609	29100068	Disco sierra	Pieza
5610	29100069	Doblar varilla manual	Pieza
5611	29100070	Domatoro o nariguero (implemento agricola)	Pieza
5612	29100071	Encendedor-desechable	Pieza
5613	29100072	Entibador	Pieza
5614	29100073	Escalera	Pieza
5615	29100074	Escantillon	Pieza
5616	29100075	Escobilla distribuidor	Pieza
5617	29100076	Escochebre	Pieza
5618	29100077	Escofina	Pieza
5619	29100078	Escoplo manual	Pieza
5620	29100079	Escuadra albañil	Pieza
5621	29100080	Escuadra carpintero	Pieza
5622	29100081	Eslinga	Pieza
5623	29100082	Esmerilador manual asentar valvulas	Pieza
5624	29100083	Espatula	Pieza
5625	29100084	Espatula cemento	Pieza
5626	29100085	Estacion reloj vigilante	Pieza
5627	29100086	Extension flexible inoxidable (manguera para acoplar sistema de vacio)	Pieza
5628	29100087	Extension manguera contra incendio	Pieza
5629	29100088	Extension matraca	Pieza
5630	29100089	Extractor baleros	Pieza
5631	29100090	Extractor bujes	Pieza
5632	29100091	Extractor masas	Pieza
5633	29100092	Extractor poleas	Pieza
5634	29100093	Extractor soldadura (chupon o jeringa)	Pieza
5635	29100094	Extractor terminal baterias	Pieza
5636	29100095	Extractor tornillos (birlos)	Pieza
5637	29100096	Extractor volante direccion	Pieza
5638	29100097	Falsa escuadra	Pieza
5639	29100098	Fleje de plastico	Pieza
5640	29100099	Flexometro	Pieza
5641	29100100	Fondo de tamizador (accesorio del tamizador recolector de polvos )	Pieza
5642	29100101	Formon	Pieza
5643	29100102	Galapago	Pieza
5644	29100103	Garlopa (manual)	Pieza
5645	29100104	Garlopin	Pieza
5646	29100105	Gradilla (molde)	Pieza
5647	29100106	Gramil	Pieza
5648	29100107	Grapa banda	Pieza
5649	29100108	Grasera	Pieza
5650	29100109	Grillete	Pieza
5651	29100110	Guia afilar sierra	Pieza
5652	29100111	Guia alambrar	Pieza
5653	29100112	Guia dados	Pieza
5654	29100113	Guia espigas	Pieza
5655	29100114	Guillame	Pieza
5656	29100115	Gurbia	Pieza
5657	29100116	Hacha	Pieza
5658	29100117	Herramienta cambio membrana estabilometro	Pieza
5659	29100118	Heterodino	Pieza
5660	29100119	Hierro marcar (implemento agricola)	Pieza
5661	29100120	Hoz (implemento agricola)	Pieza
5662	29100121	Indentador penetrador de diamante (accesorio del durometro)	Pieza
5663	29100122	Jarra (patron)	Pieza
5664	29100123	Juego de dados (autocle)	Pieza
5665	29100124	Juego de llaves españolas	Pieza
5666	29100125	Juego de pesas de calibracion (estuche con masas) (articulos para comercios)	Pieza
5667	29100126	Letra numero golpe	Pieza
5668	29100127	Lima	Pieza
5669	29100128	Limaton	Pieza
5670	29100129	Lingotera	Pieza
5671	29100130	Llana	Pieza
5672	29100131	Llave allen	Pieza
5673	29100132	Llave apretar arana bomba	Pieza
5674	29100133	Llave broquero	Pieza
5675	29100134	Llave cincho	Pieza
5676	29100135	Llave corona	Pieza
5677	29100136	Llave cuadro	Pieza
5678	29100137	Llave cubo	Pieza
5679	29100138	Llave cunas imprenta	Pieza
5680	29100139	Llave desconectar mole-drill	Pieza
5681	29100140	Llave doblar grapas	Pieza
5682	29100141	Llave empalme	Pieza
5683	29100142	Llave española	Pieza
5684	29100143	Llave estopero	Pieza
5685	29100144	Llave estrella	Pieza
5686	29100145	Llave estrias	Pieza
5687	29100146	Llave gancho	Pieza
5688	29100147	Llave inglesa	Pieza
5689	29100148	Llave macho	Pieza
5690	29100149	Llave masas	Pieza
5691	29100150	Llave media luna	Pieza
5692	29100151	Llave mixta	Pieza
5693	29100152	Llave punterias	Pieza
5694	29100153	Llave quitar tuerca lavabo	Pieza
5695	29100154	Llave stilson	Pieza
5696	29100155	Llave tablero	Pieza
5697	29100156	Llave terminales	Pieza
5698	29100157	Machete	Pieza
5699	29100159	Machuelo	Pieza
5700	29100160	Maneral brocas	Pieza
5701	29100161	Maneral en "t"	Pieza
5702	29100162	Maneral machuelo	Pieza
5703	29100163	Maneral para tarraja	Pieza
5704	29100164	Maneral para y con rodaja	Pieza
5705	29100165	Maneral soldar autogena	Pieza
5706	29100166	Mango herramienta	Pieza
5707	29100167	Manivela	Pieza
5708	29100168	Marcador transparencia	Pieza
5709	29100169	Marro	Pieza
5710	29100170	Martillo bola	Pieza
5711	29100171	Martillo hacha	Pieza
5712	29100172	Martillo hojalatero	Pieza
5713	29100173	Martillo joyero	Pieza
5714	29100174	Martillo minero	Pieza
5715	29100175	Martillo oreja	Pieza
5716	29100176	Martillo tapicero	Pieza
5717	29100177	Martillo uña	Pieza
5718	29100178	Martillos	Pieza
5719	29100179	Matraca	Pieza
5720	29100180	Mazo	Pieza
5721	29100181	Micrometro	Pieza
5722	29100182	Molleron	Pieza
5723	29100183	Mordaza	Pieza
5724	29100184	Navaja	Pieza
5725	29100185	Nivel	Pieza
5726	29100186	Nivel redondo bolsillo	Pieza
5727	29100187	Niveleta albañil	Pieza
5728	29100188	Opresor montar anillos	Pieza
5729	29100189	Pala	Pieza
5730	29100190	Palanca freno malacate	Pieza
5731	29100191	Palanca torsion	Pieza
5732	29100192	Pata de cabra	Pieza
5733	29100193	Peinazo	Pieza
5734	29100194	Perico (llave)	Pieza
5735	29100195	Perro o mordaza	Pieza
5736	29100196	Pescador	Pieza
5737	29100197	Pestanadora	Pieza
5738	29100198	Pica geologo	Pieza
5739	29100199	Picos	Pieza
5740	29100200	Piedra asentar	Pieza
5741	29100201	Piedra esmeril	Pieza
5742	29100202	Piedra lampara carburo	Pieza
5743	29100203	Pinula	Pieza
5744	29100204	Pinza angulo	Pieza
5745	29100205	Pinza balatas	Pieza
5746	29100206	Pinza cable via	Pieza
5747	29100207	Pinza caiman	Pieza
5748	29100208	Pinza corta alambre	Pieza
5749	29100209	Pinza de punta	Pieza
5750	29100210	Pinza electricidad	Pieza
5751	29100211	Pinza escurridora	Pieza
5752	29100212	Pinza extensora de resortes	Pieza
5753	29100213	Pinza mecanico	Pieza
5754	29100214	Pinza mosquito	Pieza
5755	29100215	Pinza ojilladora	Pieza
5756	29100216	Pinza pata de cabra	Pieza
5757	29100217	Pinza pelacables	Pieza
5758	29100218	Pinza pelar alambre	Pieza
5759	29100219	Pinza perico	Pieza
5760	29100220	Pinza plana	Pieza
5761	29100221	Pinza porta fusible	Pieza
5762	29100222	Pinza presion	Pieza
5763	29100223	Pinza punto pico	Pieza
5764	29100224	Pinza revelado	Pieza
5765	29100225	Pinza sacabocados	Pieza
5766	29100226	Pinza seguro valvulas	Pieza
5767	29100227	Pinza sellos plomo	Pieza
5768	29100228	Pinza tornillo	Pieza
5769	29100229	Pinzas tipo relojero	Pieza
5770	29100230	Pistola de presion para agua	Pieza
5771	29100231	Planchuela	Pieza
5772	29100232	Plomada albañil	Pieza
5773	29100233	Plomada optico	Pieza
5774	29100234	Plomo	Pieza
5775	29100235	Polea	Pieza
5776	29100236	Ponedero-jaula	Pieza
5777	29100237	Porta barra	Pieza
5778	29100238	Porta brocha	Pieza
5779	29100239	Porta cables perforadora	Pieza
5780	29100240	Porta electrodos	Pieza
5781	29100241	Porta extensometro	Pieza
5782	29100242	Porta herramientas	Pieza
5783	29100243	Porta lampara	Pieza
5784	29100244	Prensa manual cables acero	Pieza
5785	29100245	Rajador tuberia	Pieza
5786	29100246	Raspador	Pieza
5787	29100247	Rasqueta	Pieza
5788	29100248	Rastrillo	Pieza
5789	29100249	Regla tension sierra	Pieza
5790	29100250	Remachador manual	Pieza
5791	29100251	Resorte litera	Pieza
5792	29100252	Reten	Pieza
5793	29100253	Rociador insecticida	Pieza
5794	29100254	Sacabocado	Pieza
5795	29100255	Sacaclavo	Pieza
5796	29100256	Sacatestigos	Pieza
5797	29100257	Sargento carpintero	Pieza
5798	29100258	Secadora pelo	Pieza
5799	29100259	Segueta	Pieza
5800	29100260	Serrote	Pieza
5801	29100261	Serrucho	Pieza
5802	29100262	Sifon	Pieza
5803	29100263	Silleta	Pieza
5804	29100264	Soldadura autogena	Pieza
5805	29100265	Soldadura electrica	Pieza
5806	29100266	Sonda tuberia	Pieza
5807	29100267	Soplete gas	Pieza
5808	29100268	Soporte flechas transmision	Pieza
5809	29100269	Soporte gondola	Pieza
5810	29100270	Soporte ruedas	Pieza
5811	29100271	Talacho	Pieza
5812	29100272	Taladro	Pieza
5813	29100273	Tarraja para tubo	Pieza
5814	29100274	Tas	Pieza
5815	29100275	Taza balero rodillo	Pieza
5816	29100276	Tenaza	Pieza
5817	29100277	Tensor	Pieza
5818	29100278	Tijera cortar lamina	Pieza
5819	29100279	Tijera cortar uvas	Pieza
5820	29100280	Tijera podar	Pieza
5821	29100281	Tijera recta	Pieza
5822	29100282	Tiroleta	Pieza
5823	29100283	Torcedor alambre	Pieza
5824	29100284	Trabador de serrote	Pieza
5825	29100285	Triscador manual	Pieza
5826	29100286	Troquel	Pieza
5827	29100287	Uñeta acero	Pieza
5828	29100288	Verduguillo o estoque	Pieza
5829	29100289	Virola	Pieza
5830	29100290	Zapapico	Pieza
5831	29100291	Zaranda, cedazo, tamiz	Pieza
5832	29100292	Cebadera para roedor	Pieza
5833	29100293	Trampa engomada para roedor	Pieza
5834	29100294	Bozal (todo tipo de material) para animales	Pieza
5835	29100295	Afilador de cuchillo	Pieza
5836	29100296	Aflojatodo	Pieza
5837	29100298	Cuchillas desechables	Pieza
5838	29100299	Escalerilla	Pieza
5839	29100300	Espuma expandible	Pieza
5840	29100301	Estencil	Pieza
5841	29100302	Extension mecanica	Pieza
5842	29100303	Ganzuas	Pieza
5843	29100304	Garlopas	Pieza
5844	29100305	Guia (herramientas menores)	Pieza
5845	29100306	Piedra para taladro	Pieza
5846	29100307	Pinza	Pieza
5847	29100308	Pistola	Pieza
5848	29100309	Soporte pantallas (t.v.)	Pieza
5849	29100310	Torquimetro	Pieza
5850	29100311	Aire comprimido	Pieza
5851	29100312	Aplicador de ligas	Pieza
5852	29100313	Transportadora de animales	Pieza
5853	29100314	Grapas para fleje	Pieza
5854	29100315	Refacciones y accesorios para prensa	Pieza
5855	29100316	Rodillo para pintar	Pieza
5856	29100317	Centrador de esquinas	Pieza
5857	29100318	Botador	Pieza
5858	29100319	Brocas	Pieza
5859	29100320	Caja a inglete	Pieza
5860	29100321	Gubia	Pieza
5861	29100322	Accesorios para pistola (boquillas, agitador, etc.)	Pieza
5862	29100323	Detector de metales	Pieza
5863	29100324	Vernier pie de rey	Pieza
5864	29100325	Refacciones y accesorios para desbrozadora	Pieza
5865	29100326	Cinta de aluminio	Pieza
5866	29100327	Charola para rodillo	Pieza
5867	29100328	Extension para rodillo	Pieza
5868	2920	Refacciones y accesorios menores de edificios	
5869	29201	Refacciones y accesorios menores de edificios	
5870	29200001	Aldaba	Pieza
5871	29200002	Bisagra	Pieza
5872	29200003	Bomba cierrapuertas	Pieza
5873	29200004	Buzon (cartas)	Pieza
5874	29200005	Cerraduras	Pieza
5875	29200006	Cerraton	Pieza
5876	29200007	Cespol	Pieza
5877	29200008	Chapa (cerradura)	Pieza
5878	29200009	Cono cespol (adaptador)	Pieza
5879	29200010	Contracarril (ferreteria)	Pieza
5880	29200011	Contrapeso	Pieza
5881	29200012	Cople mangueras	Pieza
5882	29200013	Espejo pared	Pieza
5883	29200014	Flotador (tanque almacenamiento)	Pieza
5884	29200015	Forjas cerrajeria	Pieza
5885	29200016	Gancho y armella	Pieza
5886	29200017	Jaladeras	Pieza
5887	29200018	Llave codo	Pieza
5888	29200019	Llave cola	Pieza
5889	29200020	Llave de paso grifo	Pieza
5890	29200021	Mensula	Pieza
5891	29200022	Palanca tanque bajo w.c.	Pieza
5892	29200023	Pasador	Pieza
5893	29200024	Pasadores (cerradura)	Pieza
5894	29200025	Pata cortinero	Pieza
5895	29200026	Pera perfecta w.c.	Pieza
5896	29200027	Picaporte	Pieza
5897	29200028	Portatoallas	Pieza
5898	29200029	Regadera	Pieza
5899	29200030	Seguro	Pieza
5900	29200031	Tanques de polietileno de alta densidad	Pieza
5901	29200032	Tapa asiento w.c.	Pieza
5902	29200033	Timbre golpe	Pieza
5903	29200034	Rima manual	Pieza
5904	29200035	Portaburil	Pieza
5905	29200036	Accesorios para sanitarios	Pieza
5906	29200037	Canaleta	Pieza
5907	29200038	Perilla	Pieza
5908	29200039	Tope de piso	Pieza
5909	29200040	Guarda polvo (cubre polvo)	Pieza
5910	29200041	Mirilla	Pieza
5911	2930	Refacciones y accesorios menores de mobiliario y equipo de administracion, educacional y recreativo	
5912	29301	Refacciones y accesorios menores de mobiliario y equipo de administracion, educacional y recreativo	
5913	29300001	Anillo cortina	Pieza
5914	29300002	Arandelas, laina, rondana	Pieza
5915	29300003	Armella	Pieza
5916	29300004	Brocha	Pieza
5917	29300005	Broche riel	Pieza
5918	29300006	Capuchon lampara gas	Pieza
5919	29300007	Cepillo (herramienta)	Pieza
5920	29300008	Cepillo alambre	Pieza
5921	29300009	Cepillo carpintero	Pieza
5922	29300010	Cepillo codo	Pieza
5923	29300011	Chaveta	Pieza
5924	29300012	Clavo	Pieza
5925	29300013	Malla alambre	Pieza
5926	29300014	Pijas	Pieza
5927	29300015	Remaches	Pieza
5928	29300016	Tachuela	Pieza
5929	29300017	Taquete	Pieza
5930	29300018	Regaton	Pieza
5931	29300019	Zapata	Pieza
5932	29300020	Refacciones maq. escribir electrica (pantalla digital, motor)	Pieza
5933	29300021	Asta bandera	Pieza
5934	29300022	Portabandera	Pieza
5935	29300023	Valvula para balon	Pieza
5936	29300024	Bomba de aire para balon	Pieza
5937	2940	Refacciones y accesorios menores de equipo de computo y tecnologias de la informacion	
5938	29401	Refacciones y accesorios para equipo de computo y telecomunicaciones	
5939	29400001	Amplificador telefono (suministros informaticos)	Pieza
5940	29400002	Bocinas para multimedia (suministros informaticos)	Pieza
5941	29400003	Caja de computacion en paralelas	Pieza
5942	29400004	Cargador de baterias para equipo de computo portatil (suministros informaticos)	Pieza
5943	29400005	Chasis de tarjetas de computo para redes (para rack) (suministros informaticos)	Pieza
5944	29400006	Concentradores para redes de microcomputadoras (suministros informaticos)	Pieza
5945	29400007	Conector adaptador para fuente de poder ininterrumpida (ups) (suministros informaticos)	Pieza
5946	29400008	Control remoto para reproductora de video	Pieza
5947	29400009	Control remoto para televisor	Pieza
5948	29400010	Control remoto para videograbadora	Pieza
5949	29400011	Cortador cintas magneticas (suministros informaticos)	Pieza
5950	29400012	Disco duro para microcomputadora (suministros informaticos)	Pieza
5951	29400013	Equipo para prueba conmutador (suministros informaticos)	Pieza
5952	29400014	Gabinete para cpu (suministros informaticos)	Pieza
5953	29400015	Impresora codigos (suministros informaticos)	Pieza
5954	29400016	Impresora de baterias o corriente alterna (portatil) (suministros informaticos)	Pieza
5955	29400017	Interfaces o acopladores para microcomputadoras (suministros informaticos)	Pieza
5956	29400018	Juego de tractores (refaccion para impresora) (suministros informaticos)	Pieza
5957	29400019	Lector magnetico para microcomputadoras (suministros informaticos)	Pieza
5958	29400020	Lector optico para microcomputadoras (suministros informaticos)	Pieza
5959	29400021	Maquina certificadora-limpiadora cintas (suministros informaticos)	Pieza
5960	29400022	Modem asincrono (suministros informaticos)	Pieza
5961	29400023	Modem sincrono (suministros informaticos)	Pieza
5962	29400024	Modulo de martillos (refaccion para impresora) (suministros informaticos)	Pieza
5963	29400025	Modulo de memoria para microcomputadora (suministros informaticos)	Pieza
5964	29400026	Monitor (suministros informaticos)	Pieza
5965	29400027	Mouse (raton) accesorio de computacion (suministros informaticos)	Pieza
5966	29400028	Multiplexor (suministros informaticos)	Pieza
5967	56300130	Topadora	Pieza
5968	29400029	Multiplexor para impresoras (suministros informaticos)	Pieza
5969	29400030	Multiplexores para redes de microcomputadoras (suministros informaticos)	Pieza
5970	29400031	No-break para microcomputadoras (suministros informaticos)	Pieza
5971	29400032	Pantalla antireflejante (suministros informaticos)	Pieza
5972	29400033	Pantalla catodica (terminal de video) (suministros informaticos)	Pieza
5973	29400034	Ploter para microcomputadoras (suministros informaticos)	Pieza
5974	29400035	Porta cintas magneticas (suministros informaticos)	Pieza
5975	29400036	Porta impresora (suministros informaticos)	Pieza
5976	29400037	Portateclado para microcomputadoras (suministros informaticos)	Pieza
5977	29400038	Probador de cableado de redes de computo (suministros informaticos)	Pieza
5978	29400039	Radio modem (suministros informaticos)	Pieza
5979	29400040	Repetidores para redes de microcomputadoras (suministros informaticos)	Pieza
5980	29400041	Ruteadores para redes de microcomputadoras (suministros informaticos)	Pieza
5981	29400042	Scanner para microcomputadoras (suministros informaticos)	Pieza
5982	29400043	Supresor de transitorios (tvss) (suministros informaticos)	Pieza
5983	29400044	Tarjeta de red (suministros informaticos)	Pieza
5984	29400045	Tarjetas electronicas para microcomputadoras (suministros informaticos)	Pieza
5985	29400046	Teclado para computador (suministros informaticos)	Pieza
5986	29400047	Unidad cinta magnetica para microcomputadora (suministros informaticos)	Pieza
5987	29400048	Unidad de cinta de carrete (suministros informaticos)	Pieza
5988	29400049	Unidad externa  (suministros informaticos)	Pieza
5989	29400050	Unidad lectora y/o grabadora de disco compacto (CD y DVD) para microcomputadora (suministros informaticos)	Pieza
5990	29400051	Conector	Pieza
5991	29400052	Diskettes	Pieza
5992	29400053	Dispositivo de almacenamiento externo (USB)	Pieza
5993	29400054	Accesorio de impresora	Pieza
5994	29400055	Fusor para Impresora	Pieza
5995	29400056	Protector de pantalla	Pieza
5996	29400057	Dispositivo de almacenamiento externo (SD, Micro SD)	Pieza
5997	29400058	Tarjeta para ruteador	Pieza
5998	29400059	Unidad de diskette	Pieza
5999	29400060	Ventilador para computadores	Pieza
6000	29400061	Cabezal de impresion	Pieza
6001	29400063	Puertos (USB y HDMI)	Pieza
6002	29400065	Camaras (suministros informaticos)	Pieza
6003	29400066	Amplificador HDMI	Pieza
6004	29400067	Audifonos	Pieza
6005	29400068	Cable HDMI	Pieza
6006	29400069	Cable VGA	Pieza
6007	29400070	Adaptador convertidor de video	Pieza
6008	29400071	Tambor para impresora	Pieza
6009	2950	Refacciones y accesorios menores de equipo e instrumental medico y de laboratorio	
6010	29501	Refacciones y accesorios menores de equipo e instrumental medico y de laboratorio	
6011	29500001	Recipiente  para medir gas toron	Pieza
6012	29500002	Recipiente para medir gas radon	Pieza
6013	29500003	Fuente puntual de cobalto-60 (realiza mediciones de radiacion)	Pieza
6014	29500004	Frasco para medir radon en agua (frascos de vidrio con tapa especial)	Pieza
6015	29500005	Accesorios de equipo e instrumental medico y de laboratorio	Pieza
6016	29500006	Protectores para cama	Pieza
6017	29500007	Resorte (equipo medico y laboratorio)	Pieza
6018	29500008	Refacciones menores de equipo e instrumental medico y de laboratorio	Pieza
6019	29500009	Accesorios menores de equipo e instrumental medico y de laboratorio	Pieza
6020	29500010	Tarimas	Pieza
6021	2960	Refacciones y accesorios menores de equipo de transporte	
6022	29601	Refacciones y accesorios menores de equipo de transporte	
6023	29600001	Aguja cambio via de ferrocarril	Pieza
6024	29600002	Ajustador frenos	Pieza
6025	29600003	Alcancia (servicio de transporte publico)	Pieza
6026	29600004	Alternador automovil	Pieza
6027	29600005	Amortiguador (automotriz)	Pieza
6028	29600006	Amperimetro automovil	Pieza
6029	29600007	Anillo helicoidal enfoque	Pieza
6030	29600008	Anillo mecanico	Pieza
6031	29600009	Arbol cambio via ferrea	Pieza
6032	29600010	Arbol de levas (automotriz)	Pieza
6033	29600011	Arreo, herraje decorativo (automotriz)	Pieza
6034	29600012	Balancin punterias (automotriz)	Pieza
6035	29600013	Balata frenos (automotriz)	Pieza
6036	29600014	Banda de transmision (automotriz)	Pieza
6037	29600015	Barra direccion (automotriz)	Pieza
6038	29600016	Barra estabilizadora (automotriz)	Pieza
6039	29600017	Barra proteccion (roll-bar) (automotriz)	Pieza
6040	29600018	Bayoneta medir niveles (aceite, motor, direccion hidraulica) (automotriz)	Pieza
6041	29600019	Bendix marcha (automotriz)	Pieza
6042	29600020	Birlo	Pieza
6043	29600021	Bobina automotriz	Pieza
6044	29600022	Bobina panal	Pieza
6045	29600023	Bobina reostato	Pieza
6046	29600024	Bola diferencial (automotriz)	Pieza
6047	29600025	Bomba aceite (automotriz)	Pieza
6048	29600026	Bomba agua automovil (automotriz)	Pieza
6049	29600027	Bomba combustible (automotriz)	Pieza
6050	29600028	Bomba frenos (automotriz)	Pieza
6051	29600029	Bomba manual inflar camaras	Pieza
6052	29600030	Bomba piston manual	Pieza
6053	29600031	Brazo direccion (automotriz)	Pieza
6054	29600032	Brazo loco (automotriz)	Pieza
6055	29600033	Brazo pitman (automotriz)	Pieza
6056	29600034	Bridas para ferrocarril	Pieza
6057	29600035	Buje (automotriz)	Pieza
6058	29600036	Bujias	Pieza
6059	29600037	Bulbo aceite	Pieza
6060	29600038	Bulbo temperatura	Pieza
6061	29600039	Buzo punterias (automotriz)	Pieza
6062	29600040	Cabeza motor (automotriz)	Pieza
6063	29600041	Cables bujias (juego)	Pieza
6064	29600042	Cables pasa corriente	Pieza
6065	29600043	Cadena distribucion (automotriz)	Pieza
6066	29600044	Caja colectora dinero (automotriz)	Pieza
6067	29600045	Caja de transmision (automotriz)	Pieza
6068	29600046	Caja encendido electronico automovil	Pieza
6069	29600047	Calibrador	Pieza
6070	29600048	Calibrador llave	Pieza
6071	29600049	Calibrador mecanico	Pieza
6072	29600050	Camara de hule para aeronaves	Pieza
6073	29600051	Camara de hule para camionetas	Pieza
6074	29600052	Camaras de hule para automovil	Pieza
6075	29600053	Camaras de hule para bicicleta	Pieza
6076	29600054	Camaras de hule para camion	Pieza
6077	29600055	Camaras de hule para motocicleta	Pieza
6078	29600056	Camaras y bandas de hule de proteccion	Pieza
6079	29600057	Canastilla  (automotriz)	Pieza
6080	29600058	Candado balatas	Pieza
6081	29600059	Candelero caja velocidades (automotriz)	Pieza
6082	29600060	Capuchon cabeza motor (automotriz)	Pieza
6083	29600061	Carburador (automotriz)	Pieza
6084	29600062	Carter (automotriz)	Pieza
6085	29600063	Chicote (acelerador-frenos-clutch-tacometro) (automotriz)	Pieza
6086	29600064	Cigüeñal (automotriz)	Pieza
6087	29600065	Cilindro freno (automotriz)	Pieza
6088	29600066	Cilindro prueba proctor	Pieza
6089	29600067	Clavo via ferrea	Pieza
6090	29600068	Claxon	Pieza
6091	29600069	Cofre (automotriz)	Pieza
6092	29600070	Coladera (automotriz)	Pieza
6093	29600071	Coladera aceite motor (automotriz)	Pieza
6094	29600072	Colgador gondola	Pieza
6095	29600073	Collarin (automotriz)	Pieza
6096	29600074	Columpio muelle (automotriz)	Pieza
6097	29600075	Contracarril (ferrocarril)	Pieza
6098	29600076	Cople direccion (automotriz)	Pieza
6099	29600077	Corbatas p/llantas de camion	Pieza
6100	29600078	Corona y piñon diferencial (automotriz)	Pieza
6101	29600079	Cremallera	Pieza
6102	29600080	Cremallera volante motor (automotriz)	Pieza
6103	29600081	Cremalleras (ferrocarril)	Pieza
6104	29600082	Cruces o cambios de via de ferrocarril	Pieza
6105	29600083	Cruceta cardan (automotriz)	Pieza
6106	29600084	Cubierta automovil	Pieza
6107	29600085	Cubre polvo horquilla (automotriz)	Pieza
6108	29600086	Cubreasientos	Pieza
6109	29600087	Cuenca maroma clutch (automotriz)	Pieza
6110	29600088	Dado bujia	Pieza
6111	29600089	Direccion automovil	Pieza
6112	29600090	Disco clutch (pasta) (automotriz)	Pieza
6113	29600091	Distribuidor	Pieza
6114	29600092	Divisor canastilla	Pieza
6115	29600093	Divisor gondola	Pieza
6116	29600094	Ejes (ferrocarril)	Pieza
6117	29600095	Electrolito p/acumulador (automotriz)	Pieza
6118	29600096	Elevador cristal puerta (automotriz)	Pieza
6119	29600097	Engrane (automotriz)	Pieza
6120	29600098	Eslabon cadena de transmision	Pieza
6121	29600099	Espaciador (automotriz)	Pieza
6122	29600100	Esparrago (material de ferreteria)	Pieza
6123	29600101	Espejo inspeccion	Pieza
6124	29600102	Espejo retrovisor exterior (automotriz)	Pieza
6125	29600103	Espejo retrovisor interior (automotriz)	Pieza
6126	29600104	Estator alternador	Pieza
6127	29600105	Filtro (separadores de sedimentos)	Pieza
6128	29600106	Filtro de aceite (automotriz)	Pieza
6129	29600107	Filtro de aire (automotriz)	Pieza
6130	29600108	Filtro de gasolina (automotriz)	Pieza
6131	29600109	Flauta balancines (automotriz)	Pieza
6132	29600110	Flecha cardan (automotriz)	Pieza
6133	29600111	Flecha diferencial (automotriz)	Pieza
6134	29600112	Flecha mando transmision (automotriz)	Pieza
6135	29600113	Flotador carburador (automotriz)	Pieza
6136	29600114	Flotador tanque combustible (automotriz)	Pieza
6137	29600115	Freno electrico (automotriz)	Pieza
6138	29600116	Funda bayoneta aceite (automotriz)	Pieza
6139	29600117	Funda velocimetro (automotriz)	Pieza
6140	29600118	Gato hidraulico (automotriz)	Pieza
6141	29600119	Gato mecanico (automotriz)	Pieza
6142	29600120	Guia clutch (automotriz)	Pieza
6143	29600121	Hoja muelle automovil (automotriz)	Pieza
6144	29600122	Horquilla clutch (automotriz)	Pieza
6145	29600123	Horquilla suspension inferior (automotriz)	Pieza
6146	29600124	Horquilla suspension superior (automotriz)	Pieza
6147	29600125	Impulsor electronico	Pieza
6148	29600126	Indicador presion aceite automovil	Pieza
6149	29600127	Limpia parabrisas (brazo y pluma) (automotriz)	Pieza
6150	29600128	Limpia parabrisas (brazo) (automotriz)	Pieza
6151	29600129	Limpia parabrisas (pluma) (automotriz)	Pieza
6152	29600130	Liquido frenos (automotriz)	Pieza
6153	29600131	Llantas de hule para aeronaves	Pieza
6154	29600132	Llantas de hule para automovil	Pieza
6155	29600133	Llantas de hule para bicicleta	Pieza
6156	29600134	Llantas de hule para camion	Pieza
6157	29600135	Llantas de hule para camioneta	Pieza
6158	29600136	Llantas de hule para maquinaria agricola	Pieza
6159	29600137	Llantas de hule para motocicleta	Pieza
6160	29600138	Llantas de hule para sistema de transporte  colectivo (stc)	Pieza
6161	29600139	Llave bicicleta	Pieza
6162	29600140	Llave bujias	Pieza
6163	29600141	Llave cadena	Pieza
6164	29600142	Llave calavera	Pieza
6165	29600143	Llave cluth	Pieza
6166	29600144	Llave conexiones de carburador	Pieza
6167	29600145	Llave de cruz	Pieza
6168	29600146	Loderas (automotriz)	Pieza
6169	29600147	Magneto distribuidor	Pieza
6170	29600148	Maneral rueda camion	Pieza
6171	29600149	Mango direccion (automotriz)	Pieza
6172	29600150	Marcha (automotriz)	Pieza
6173	29600151	Maroma clutch (automotriz)	Pieza
6174	29600152	Medidor gasolina automovil	Pieza
6175	29600153	Medidor temperatura automovil	Pieza
6176	29600154	Medidor velocimetro	Pieza
6177	29600155	Medio motor (automotriz)	Pieza
6178	29600156	Motor limpiadores	Pieza
6179	29600157	Muelle (automotriz)	Pieza
6180	29600158	Multiple admision-escape (automotriz)	Pieza
6181	29600159	Ojo de buey (automotriz)	Pieza
6182	29600160	Panel radiador (automotriz)	Pieza
6183	29600161	Parabrisas (automotriz)	Pieza
6184	29600162	Parches para neumaticos	Pieza
6185	29600163	Percha muelle (automotriz)	Pieza
6186	29600164	Pivote	Pieza
6187	29600165	Pivote piston	Pieza
6188	29600166	Placa seguro porta balatas (automotriz)	Pieza
6189	29600167	Placas de asiento (ferrocarril)	Pieza
6190	29600168	Placas de tirantes (ferrocarril)	Pieza
6191	29600169	Plastigage (llantas y camaras)	Pieza
6192	29600170	Platinos	Pieza
6193	29600171	Plato freno (automotriz)	Pieza
6194	29600172	Plato opresor clutch (automotriz)	Pieza
6195	29600173	Plato porta balatas (automotriz)	Pieza
6196	29600174	Ponchadora de conectores	Pieza
6197	29600175	Porta collarin (automotriz)	Pieza
6198	29600176	Porta platinos (distribuidor) (automotriz)	Pieza
6199	29600177	Punta de corazon (ferrocarril)	Pieza
6200	29600178	Purgador frenos	Pieza
6201	29600179	Purificador automovil (pulmon) (automotriz)	Pieza
6202	29600180	Radiador (automotriz)	Pieza
6203	29600181	Ralladores para metal (automotriz)	Pieza
6204	29600182	Regulador electronico automovil	Pieza
6205	29600183	Regulador gas (automotriz)	Pieza
6206	29600184	Regulador voltaje automovil	Pieza
6207	29600185	Repuesto bomba agua (automotriz)	Pieza
6208	29600186	Repuesto cilindro maestro frenos (automotriz)	Pieza
6209	29600187	Resorte (automotriz)	Pieza
6210	29600188	Riel rodante (ferrocarril)	Pieza
6211	29600189	Rieles (ferrocarril)	Pieza
6212	29600190	Rin (automotriz)	Pieza
6213	29600191	Rodillos y rodamientos de hule	Pieza
6214	29600192	Rondana via ferrea	Pieza
6215	29600193	Rotor alternador	Pieza
6216	29600194	Rotula suspension (automotriz)	Pieza
6217	29600195	Ruedas (ferrocarril)	Pieza
6218	29600196	Salpicadera (automotriz)	Pieza
6219	29600197	Seguro flecha diferencial (automotriz)	Pieza
6220	29600198	Seguro mango direccion (rondana, tuerca, chaveta) (automotriz)	Pieza
6221	29600199	Seguro perno caja satelite (automotriz)	Pieza
6222	29600200	Seguro valvula (automotriz)	Pieza
6223	29600201	Selenoide-marcha	Pieza
6224	29600202	Sellador juntas (automotriz)	Pieza
6225	29600203	Silenciador (automotriz)	Pieza
6226	29600204	Sinfin direccion (flecha) (automotriz)	Pieza
6227	29600205	Sinfin piston potencia (muelle) (automotriz)	Pieza
6228	29600206	Soporte alternador (automotriz)	Pieza
6229	29600207	Soporte amortiguador (automotriz)	Pieza
6230	29600208	Soporte caja velocidades (automotriz)	Pieza
6231	29600209	Soporte horquilla clutch (automotriz)	Pieza
6232	29600210	Soporte maroma clutch bastidor (automotriz)	Pieza
6233	29600211	Soporte maroma clutch motor (automotriz)	Pieza
6234	29600212	Soporte resorte valvulas (automotriz)	Pieza
6235	29600213	Tambor rueda (automotriz)	Pieza
6236	29600214	Tanque combustible automovil (automotriz)	Pieza
6237	29600215	Tapa balero-rodillo (automotriz)	Pieza
6238	29600216	Tapa carter (automotriz)	Pieza
6239	29600217	Tapa punterias (automotriz)	Pieza
6240	29600218	Taquimetro mecanico (automotriz)	Pieza
6241	29600219	Templador clutch (automotriz)	Pieza
6242	29600220	Termostato radiador (automotriz)	Pieza
6243	29600221	Tirante estabilizador suspension (automotriz)	Pieza
6244	29600222	Torreta calzar vehiculo	Pieza
6245	29600223	Traviesas (ferrocarril)	Pieza
6246	29600224	Trusquin de punta (automotriz)	Pieza
6247	29600225	Tubos y mangueras de hule natural vulcanizado	Pieza
6248	29600226	Tumba burro (automotriz)	Pieza
6249	29600227	Unidad calefaccion-aire acondicionado  (automotriz)	Pieza
6250	29600228	Unidad iluminacion automovil (normal-halogeno)	Pieza
6251	29600229	Valvula admision-escape (automotriz)	Pieza
6252	29600230	Varilla direccion (automotriz)	Pieza
6253	29600231	Varilla para mando (ferrocarril)	Pieza
6254	29600232	Varilla punteria (vastago) (automotriz)	Pieza
6255	29600233	Ventilador (aspas) (automotriz)	Pieza
6256	29600234	Volante (automotriz)	Pieza
6257	29600235	Yugo caja velocidades (automotriz)	Pieza
6258	29600236	Yugo cruceta (en flecha cardan) (automotriz)	Pieza
6259	29600237	Yugo diferencial (automotriz)	Pieza
6260	29600238	Masas	Pieza
6261	29600239	Abrazaderas	Pieza
6262	29600240	Abrillantador de llantas	Pieza
6263	29600241	Asientos	Pieza
6264	29600242	Acoplador para motor	Pieza
6265	29600243	Aditamento para arrastre de vehiculos	Pieza
6266	29600244	Pasta automotriz	Pieza
6267	29600245	Piston	Pieza
6268	29600246	Plaste	Pieza
6269	29600247	Resorte (equipo de transporte)	Pieza
6270	29600248	Llave para puerta y motor de vehiculo con o sin dispositivo electronico	Pieza
6271	29600249	Refacciones y accesorios para bicicletas	Pieza
6272	29600250	Accionador del turbocargador (automotriz)	Pieza
6273	29600251	Bolsas de aire (automotriz)	Pieza
6274	29600252	Camara de freno (automotriz)	Pieza
6275	29600253	Compresor de aire (automotriz)	Pieza
6276	29600254	Empaques y juntas (automotriz)	Pieza
6277	29600255	Enfriador de aceite (automotriz)	Pieza
6278	29600256	Inyector de combustible (automotriz)	Pieza
6279	29600257	Palanca de direccionales (automotriz)	Pieza
6280	29600258	Sello o estopero de aceite (automotriz)	Pieza
6281	29600259	Switch de encendido, arranque (automotriz)	Pieza
6282	29600260	Tapon de radiador (automotriz)	Pieza
6283	29600261	Turbocompresor (automotriz)	Pieza
6284	29600262	Base para filtro de aceite	Pieza
6285	29600263	Tope de rebote de suspension	Pieza
6286	29600264	Base de barra de torsion	Pieza
6287	29600265	Base de tirantes para suspension	Pieza
6288	29600266	Base para bateria	Pieza
6289	29600267	Colector de aire	Pieza
6290	29600268	Chisguetero	Pieza
6291	29600269	Modulo tapa volante	Pieza
6292	29600270	Modulo de control de columna del volante	Pieza
6293	29600271	Unidad de control del vehiculo	Pieza
6294	29600272	Refacciones para sistema de aire	Pieza
6295	29600273	Refacciones para sistema de alumbrado	Pieza
6296	29600274	Refacciones para sistema de arranque	Pieza
6297	29600275	Refacciones para sistema de transmision	Pieza
6298	29600276	Refacciones para sistema de carga electrica	Pieza
6299	29600277	Refacciones para sistema de combustion	Pieza
6300	29600278	Refacciones para sistema de direccion	Pieza
6301	29600279	Refacciones para sistema de enfriamiento	Pieza
6302	29600280	Refacciones para sistema de escape	Pieza
6303	29600281	Refacciones para sistema de frenos	Pieza
6304	29600282	Refacciones para sistema de lubricacion	Pieza
6305	29600283	Refacciones para sistema de rodamiento	Pieza
6306	29600284	Refacciones para sistema de suspension	Pieza
6307	29600285	Refacciones para sistema de electrico	Pieza
6308	29600286	Refacciones para sistema de hidraulico	Pieza
6309	29600287	Refacciones para aeronaves	Pieza
6310	29600288	Defensa inflable para embarcaciones	Pieza
6311	2970	Refacciones y accesorios menores de equipo de defensa y seguridad	
6312	29701	Refacciones y accesorios menores de equipo de defensa y seguridad	
6313	29700001	Tafilete casco minero	Pieza
6314	29700002	Refacciones menores de equipo de defensa y seguridad	Pieza
6315	29700003	Accesorios menores de equipo de defensa y seguridad	Pieza
6316	29700004	Sellos de seguridad (marchamo)	Pieza
6317	29700005	Refacciones para sistema hidraulico (uso marino)	Pieza
6318	29700006	Refacciones para sistema propulsor (uso marino)	Pieza
6319	29700007	Refacciones para aire acondicionado (uso marino)	Pieza
6320	29700008	Refacciones para sistemas vitales (uso marino)	Pieza
6321	29700009	Refacciones para sistemas electricos (uso marino)	Pieza
6322	29700010	Defensas (uso marino)	Pieza
6323	29700011	Amortiguadores para (uso marino)	Pieza
6324	29700012	Filtro para combustible (motores marinos)	Pieza
6325	29700013	Filtro para aceite (motores marinos)	Pieza
6326	29700014	Filtro para aire (motores marinos)	Pieza
6327	29700015	Filtro para refrigerante (motores marinos)	Pieza
6328	29700016	Filtro para sistema de agua potable (maq. naval)	Pieza
6329	2980	Refacciones y accesorios menores de maquinaria y otros equipos	
6330	29801	Refacciones y accesorios menores de maquinaria y otros equipos	
6331	29800001	Acoplador antena	Pieza
6332	29800002	Balines	Pieza
6333	29800003	Banda acero	Pieza
6334	29800004	Bote sedimentador (implemento agricola)	Pieza
6335	29800005	Buje (ferreteria)	Pieza
6336	29800006	Cadena	Pieza
6337	29800007	Camaras de hule para maquinaria agricola	Pieza
6338	29800008	Candados y seguros	Pieza
6339	29800009	Casquillo	Pieza
6340	29800010	Centrador	Pieza
6341	29800011	Compas de bomba	Pieza
6342	29800012	Conector	Pieza
6343	29800013	Disco para arado (implemento agricola)	Pieza
6344	29800014	Ducto	Pieza
6345	29800015	Embudo	Pieza
6346	29800016	Empaque	Pieza
6347	29800017	Fresa (ferreteria)	Pieza
6348	29800018	Linotipo	Pieza
6349	29800019	Perno	Pieza
6350	29800020	Punta cautin	Pieza
6351	29800021	Punta repuesto vibro grabador	Pieza
6352	29800022	Punto	Pieza
6353	29800023	Punzon	Pieza
6354	29800024	Quemador lampara carburo	Pieza
6355	29800025	Rodaja riel	Pieza
6356	29800026	Rodamiento (balero)	Pieza
6357	29800027	Rodillo cadenas transmision	Pieza
6358	29800028	Soldadura	Pieza
6359	29800029	Tapadora de pulpa de acero	Pieza
6360	29800030	Tapones para tuberia	Pieza
6361	29800031	Valvula	Pieza
6362	29800032	Guadaña	Pieza
6363	29800033	Aspas	Pieza
6364	29800034	Aspersor	Pieza
6365	29800035	Baleros	Pieza
6366	29800036	Porta candado	Pieza
6367	29800037	Inserto	Pieza
6368	29800038	Porta inserto	Pieza
6369	29800039	Eslabon	Pieza
6370	29800040	Accesorio para sistema de grabado	Pieza
6371	29800041	Carro lineal	Pieza
6372	29800042	Vaiven de bola	Pieza
6373	29800043	Acoplamientos y chumaceras	Pieza
6374	29800044	Refacciones para motores fuera de borda	Pieza
6375	29800045	Calentador abierto	Pieza
6376	29800046	Rueda desecante	Pieza
6377	29800047	Retenes	Pieza
6378	29800048	Motor impulsor	Pieza
6379	29800049	Compresor	Pieza
6380	29800050	Termostato	Pieza
6381	29800051	Tapon de nitrilo	Pieza
6382	29800052	Visor protector	Pieza
6383	29800053	Polimero flexible	Pieza
6384	29800054	Filtro deshidratador	Pieza
6385	29800055	Tubo capilar	Pieza
6386	29800056	Martillo para forjado	Pieza
6387	2990	Refacciones y accesorios menores otros bienes muebles	
6388	29901	Refacciones y accesorios menores otros bienes muebles	
6389	29900001	Acuario	Pieza
6390	29900002	Anillos y rondanas de hule	Pieza
6391	29900003	Base jaula (implemento agricola)	Pieza
6392	29900004	Base microfono	Pieza
6393	29900005	Charola jaula (implemento agricola)	Pieza
6394	29900006	Charola salvamiel (implemento agricola)	Pieza
6395	29900007	Florero	Pieza
6396	29900008	Jaula (implemento agricola)	Pieza
6397	29900009	Macetas	Pieza
6398	29900010	Macetero	Pieza
6399	29900011	Mecha lampara	Pieza
6400	29900012	Medidor de paso de agua (horometro) accesorio	Pieza
6401	29900013	Micro spray	Pieza
6402	29900014	Pecera	Pieza
6403	29900015	Plantas artificiales, adorno	Pieza
6404	29900016	Porta-pañuelos	Pieza
6405	29900017	Refacciones para la industria agropecuaria	Pieza
6406	29900018	Refacciones para la industria alimentaria	Pieza
6407	29900019	Refacciones para la industria de elaboracion de bebidas	Pieza
6408	29900020	Refacciones para la industria de la construccion	Pieza
6409	29900021	Refacciones para la industria de la madera y del corcho exc.mueb.	Pieza
6410	29900022	Refacciones para la industria del calzado y del cuero	Pieza
6411	29900023	Refacciones para la industria del papel	Pieza
6412	29900024	Refacciones para la industria del tabaco	Pieza
6413	29900025	Refacciones para la industria del transporte aereo	Pieza
6414	29900026	Refacciones para la industria del transporte ferroviario	Pieza
6415	29900027	Refacciones para la industria del transporte maritimo	Pieza
6416	29900028	Refacciones para la industria del transporte metropolitano	Pieza
6417	29900029	Refacciones para la industria del transporte terrestre no ferr.	Pieza
6418	29900030	Refacciones para la industria del vestido	Pieza
6419	29900031	Refacciones para la industria editorial	Pieza
6420	29900032	Refacciones para la industria electrica	Pieza
6421	29900033	Refacciones para la industria electronica y de comunicacion	Pieza
6422	29900034	Refacciones para la industria hulera y del plastico	Pieza
6423	29900035	Refacciones para la industria mueblera	Pieza
6424	29900036	Refacciones para la industria petrolera	Pieza
6425	29900037	Refacciones para la industria quimica	Pieza
6426	29900038	Refacciones para la industria siderurgica	Pieza
6427	29900039	Refacciones para la industria textil	Pieza
6428	29900040	Tambo metalico	Pieza
6429	29900041	Tapa metalica tambo	Pieza
6430	29900042	Repuestos de olla de presion	Pieza
6431	29900043	Accesorios de equipos de tratamiento de aire	Pieza
6432	29900044	Accesorios de equipos de tratamiento de agua	Pieza
6433	29900045	Refacciones para sillas giratorias	Pieza
6434	29900046	Repuesto para encendedor	Pieza
6435	29900047	Refacciones para balsas salvavidas	Pieza
6436	29900048	Accesorios para banda de guerra (baquetas, vaso, aro, parche, piola, golpes, boquilla, etc.)	Pieza
6437	29900049	Agua tratada para acuario	Pieza
6438	29900050	Porta-anuncios (articulos para comercios)	Pieza
6439	29900051	Porta-precios (articulos para comercios)	Pieza
6440	3000	Servicios generales	
6441	3100	Servicios basicos	
6442	3110	Energia electrica	
6443	31101	Servicio de energia electrica	
6444	31100001	Servicio de energia electrica	Servicio
6445	3120	Gas	
6446	31201	Servicio gas	
6447	31200001	Servicio de gas	Servicio
6448	3130	Agua	
6449	31301	Servicio de agua	
6450	31300001	Servicio de agua	Servicio
6451	3140	Telefonia tradicional	
6452	31401	Servicio telefonico convencional	
6453	31400001	Servicio telefonico convencional	Servicio
6454	3150	Telefonia celular	
6455	31501	Servicio de telefonia celular	
6456	31500001	Servicio de telefonia celular	Servicio
6457	3160	Servicios de telecomunicaciones y satelites	
6458	31601	Servicios de radiolocalizacion	
6459	31600005	Servicio de radiolocalizacion	Servicio
6460	31602	Servicios de telecomunicaciones	
6461	31600001	Servicios de red de telecomunicaciones nacional e internacional	Servicio
6462	31603	Servicios de Internet	
6463	31600030	Servicio de internet	Servicio
6464	3170	Servicios de acceso de Internet, redes y procesamiento de informacion	
6465	31701	Servicios de conduccion de señales analogicas y digitales	
6466	31700002	Servicios de conduccion de señales analogicas y digitales	Servicio
6467	31700003	Servicios de acceso de Internet, redes y procesamiento de informacion	Servicio
6468	31700004	Servicio de television de paga	Servicio
6469	31700005	Servicios satelitales	Servicio
6470	31700006	Servicios de red digital integrada	Servicio
6471	3180	Servicios postales y telegraficos	
6472	31801	Servicio postal	
6473	31800001	Servicio postal	Servicio
6474	31802	Servicio telegrafico	
6475	31800002	Servicio telegrafico	Servicio
6476	3190	Servicios integrales y otros servicios	
6477	31901	Servicios integrales de telecomunicacion	
6478	31900001	Servicio de radiolocalizacion	Servicio
6479	31900002	Servicios integrales de telecomunicacion	Servicio
6480	31900003	Servicio de telefonia celular y radiocomunicacion	Servicio
6481	31902	Contratacion de otros servicios	
6482	31900010	Estacionamiento y servicios relacionados	Servicio
6483	31903	Servicios generales para planteles educativos	
6484	31904	Servicios integrales de infraestructura de computo	
6485	31900004	Servicios a centros de datos (hospedaje, electricidad, video vigilancia, monitoreo, aire acondicionado, servidores y otros)	Servicio
6486	3200	Servicios de arrendamiento	
6487	3210	Arrendamiento de terrenos	
6488	32101	Arrendamiento de terrenos	
6489	3220	Arrendamiento de edificios	
6490	32201	Arrendamiento de edificios y locales	
6491	3230	Arrendamiento de mobiliario y equipo de administracion, educacional y recreativo	
6492	32301	Arrendamiento de equipo y bienes informaticos	
6493	32300001	Arrendamiento de equipo de computo y bienes informaticos	Servicio
6494	32302	Arrendamiento de mobiliario	
6495	32300002	Arrendamiento de mobiliario	Servicio
6496	32303	Arrendamiento de equipo de telecomunicaciones	
6497	32300003	Arrendamiento de equipo de telecomunicaciones	Servicio
6498	3240	Arrendamiento de equipo e instrumental medico y de laboratorio	
6499	32401	Arrendamiento de equipo e instrumental medico y de laboratorio	
6500	32400001	Alquiler de equipo e instrumental de laboratorio	Servicio
6501	32400002	Alquiler de equipo e instrumental medico	Servicio
6502	3250	Arrendamiento de equipo de transporte	
6503	32501	Arrendamiento de vehiculos terrestres, aereos, maritimos, lacustres y fluviales para la ejecucion de programas de seguridad publica y nacional	
6504	32500002	Arrendamiento de vehiculos  aereos para la ejecucion de programas de seguridad publica nacional	Servicio
6505	32500007	Arrendamiento de vehiculos  fluviales para la ejecucion de programas de seguridad publica nacional	Servicio
6506	32500012	Arrendamiento de vehiculos  lacustres para la ejecucion de programas de seguridad publica nacional	Servicio
6507	32500017	Arrendamiento de vehiculos  maritimos para la ejecucion de programas de seguridad publica nacional	Servicio
6508	32500022	Arrendamiento de vehiculos  terrestres para la ejecucion de programas de seguridad publica nacional	Servicio
6509	32502	Arrendamiento de vehiculos terrestres, aereos, maritimos, lacustres y fluviales para servicios publicos y la operacion de programas publicos	
6510	32500004	Arrendamiento de vehiculos  aereos para servicios publicos y la operacion de programas publicos	Servicio
6511	32500009	Arrendamiento de vehiculos  fluviales para servicios publicos y la operacion de programas publicos	Servicio
6512	32500014	Arrendamiento de vehiculos  lacustres para servicios publicos y la operacion de programas publicos	Servicio
6513	32500019	Arrendamiento de vehiculos  maritimos para servicios publicos y la operacion de programas publicos	Servicio
6514	32500024	Arrendamiento de vehiculos  terrestres para servicios publicos y la operacion de programas publicos	Servicio
6515	32503	Arrendamiento de vehiculos terrestres, aereos, maritimos, lacustres y fluviales para servicios administrativos	
6516	32500003	Arrendamiento de vehiculos  aereos para servicios administrativos	Servicio
6517	32500008	Arrendamiento de vehiculos  fluviales para servicios administrativos	Servicio
6518	32500013	Arrendamiento de vehiculos  lacustres para servicios administrativos	Servicio
6519	32500018	Arrendamiento de vehiculos  maritimos para servicios administrativos	Servicio
6520	32500023	Arrendamiento de vehiculos  terrestres para servicios administrativos	Servicio
6521	32504	Arrendamiento de vehiculos terrestres, aereos, maritimos, lacustres y fluviales para desastres naturales	
6522	32500001	Arrendamiento de vehiculos  aereos para desastres naturales	Servicio
6523	32500006	Arrendamiento de vehiculos  fluviales para desastres naturales	Servicio
6524	32500011	Arrendamiento de vehiculos  lacustres para desastres naturales	Servicio
6525	32500016	Arrendamiento de vehiculos  maritimos para desastres naturales	Servicio
6526	32500021	Arrendamiento de vehiculos  terrestres para desastres naturales	Servicio
6527	32505	Arrendamiento de vehiculos terrestres, aereos, maritimos, lacustres y fluviales para servidores publicos	
6528	32500005	Arrendamiento de vehiculos  aereos para servidores publicos	Servicio
6529	32500010	Arrendamiento de vehiculos  fluviales para servidores publicos	Servicio
6530	32500015	Arrendamiento de vehiculos  lacustres para servidores publicos	Servicio
6531	32500020	Arrendamiento de vehiculos  maritimos para servidores publicos	Servicio
6532	32500025	Arrendamiento de vehiculos  terrestres para servidores publicos	Servicio
6533	3260	Arrendamiento de maquinaria, otros equipos y herramientas	
6534	32601	Arrendamiento de maquinaria y equipo	
6535	32600001	Arrendamiento de equipo de control y medicion	Servicio
6536	32600002	Arrendamiento de equipo medico quirurgico y de diagnostico	Servicio
6537	32600003	Arrendamiento de estructuras metalicas	Servicio
6538	32600004	Arrendamiento de maquinas de oficina	Servicio
6539	32600005	Arrendamiento de maquinas fotocopiadoras	Servicio
6540	32600006	Arrendamiento de maquinas-herramienta	Servicio
6541	32600007	Maquinaria y equipo de comunicacion (arrendamiento de)	Servicio
6542	32600008	Maquinaria y equipo de reproduccion (arrendamiento de)	Servicio
6543	32600009	Maquinaria y equipo industrial (arrendamiento de)	Servicio
6544	32600010	Maquinaria y equipo para construccion (arrendamiento de)	Servicio
6545	3270	Arrendamiento de activos intangibles	
6546	32701	Patentes, derechos de autor, regalias y otros	
6547	32700001	Acceso a la biblioteca de imagenes	Servicio
6548	32700002	Uso de patentes y marcas	Servicio
6549	32700003	Licencias de uso de programas de computo y su actualizacion	Servicio
6550	32700004	Representaciones comerciales e industriales	Servicio
6551	32700005	Regalias por derechos de autor y membrecias	Servicio
6552	3280	Arrendamiento financiero	
6553	3290	Otros arrendamientos	
6554	32901	Arrendamientos de sustancias y productos quimicos	
6555	32900001	Arrendamiento de sustancias y productos quimicos	Servicio
6556	32902	PIDIREGAS cargos fijos	
6557	32903	Otros arrendamientos	
6558	32900003	Arrendamiento de equipo relacionado con el audio, video e iluminacion	Servicio
6559	32900004	Arrendamiento de oficinas modulares prefabricadas	Servicio
6560	3300	Servicios profesionales, cientificos, tecnicos y otros servicios	
6561	3310	Servicios legales, de contabilidad, auditoria y relacionados	
6562	33101	Asesorias asociadas a convenios, tratados o acuerdos	
6563	33100003	Asesorias asociadas a convenios, tratados o acuerdos	Servicio
6564	33102	Asesorias por controversias en el marco de los tratados internacionales	
6565	33100004	Asesorias por controversias en el marco de los tratados internacionales	Servicio
6566	33103	Consultorias para programas o proyectos financiados por organismos internacionales	
6567	33100005	Consultorias para programas o proyectos financiados por organismos internacionales	Servicio
6568	33104	Otras asesorias para la operacion de programas	
6569	33100001	Asesoria en aspectos juridicos del proceso de reestructuracion y modernizacion del sector energetico	Servicio
6570	33100002	Asesorias para la operacion de programas	Servicio
6571	33105	Servicios relacionados con procedimientos jurisdiccionales	
6572	33100006	Servicios legales	Servicio
6573	33100007	Servicios de contabilidad	Servicio
6574	33100008	Servicios de auditoria	Servicio
6575	3320	Servicios de diseño, arquitectura, ingenieria y actividades relacionadas	
6576	33201	Servicios de diseño, arquitectura, ingenieria y actividades relacionadas	
6577	33200004	Servicios de ingenieria civil	
6578	3330	Servicios de consultoria administrativa, procesos, tecnica y en tecnologias de la informacion	
6579	33301	Servicios de desarrollo de aplicaciones informaticas	
6580	33300001	Servicios de informatica	Servicio
6581	33300006	Desarrollo y mantenimiento de sistemas (paginas de internet, elaboracion de programas)	Servicio
6582	33300007	Ploteo por computadora	Servicio
6583	33300008	Reproduccion de informacion en medios magneticos	Servicio
6584	33302	Servicios estadisticos y geograficos	
6585	33300002	Servicios estadisticos	Servicio
6586	33300003	Servicios estadisticos y geograficos	Servicio
6587	33300004	Servicios geograficos	Servicio
6588	33303	Servicios relacionados con certificacion de procesos	
6589	33300005	Servicios de consultoria	Servicio
6590	33300015	Certificacion de modelos de gestion	Servicio
6591	33304	Servicio de mantenimiento de aplicaciones informaticas	
6592	33300009	Mantenimiento y/o soporte a sistemas y/o programas ya existentes	Servicio
6593	3340	Servicios de capacitacion	
6594	33401	Servicios para capacitacion a servidores publicos	
6595	33400001	Servicios para capacitacion a servidores publicos	Servicio
6596	3350	Servicios de investigacion cientifica y desarrollo	
6597	33501	Estudios e investigaciones	
6598	33500001	Investigacion y desarrollo en ciencias fisicas	Servicio
6599	33500002	Investigacion y desarrollo en ciencias de la vida	Servicio
6600	33500003	Investigacion y desarrollo en ingenieria	Servicio
6601	33500004	Investigacion y desarrollo en quimica	Servicio
6602	33500005	Investigacion y desarrollo en oceanografia	Servicio
6603	33500006	Investigacion y desarrollo en geologia	Servicio
6604	33500007	Investigacion y desarrollo en matematicas	Servicio
6605	33500008	Investigacion y desarrollo en ciencias sociales	Servicio
6606	33500009	Investigacion y desarrollo en humanidades	Servicio
6607	33500010	Estudios e investigaciones	Servicio
6608	3360	Servicios de apoyo administrativo, traduccion, fotocopiado e impresion	
6609	33601	Servicios relacionados con traducciones	
6610	33601001	Servicios relacionados con traducciones	Servicio
6611	33602	Otros servicios comerciales	
6612	33602001	Vales para el dia del niño (prestaciones)	Servicio
6613	33602002	Vales para el dia de la madre (prestaciones)	Servicio
6614	33602003	Vales estimulo al empleado del mes (prestaciones)	Servicio
6615	33602004	Vales canjeables por despensa (prestaciones)	Servicio
6616	33602005	Vales canjeables por despensa fin de año (prestaciones)	Servicio
6617	33602006	Vales de alimentacion	Servicio
6618	33602007	Vales canjeables por gasolina	Servicio
6619	33602008	Otros servicios comerciales	Servicio
6620	33602009	Servicio de fotocopiado	Servicio
6621	33602010	Servicio de engargolado	Servicio
6622	33602011	Servicio de impresion	Servicio
6623	33603	Impresiones de documentos oficiales para la prestacion de servicios publicos, identificacion, formatos administrativos y fiscales, formas valoradas, certificados y titulos	
6624	33600002	Servicio de impresion de documentos oficiales para la prestacion de serv. Pub.	Servicio
6625	33604	Impresion y elaboracion de material informativo derivado de la operacion y administracion de las dependencias y entidades	
6626	33600001	Impresion y elaboracion de publicaciones oficiales y de informacion en general para difusion	Servicio
6627	33605	Informacion en medios masivos derivada de la operacion y administracion de las dependencias y entidades	
6628	33600003	Informacion en medios masivos derivada de la operacion y administracion de las dependencias y entidades	Servicio
6629	33606	Servicio de digitalizacion	
6630	33600004	Digitalizacion de documentos	Servicio
6631	33600005	Captura de datos en sistemas de computo	Servicio
6632	3370	Servicios de proteccion y seguridad	
6633	33701	Gastos de seguridad publica y nacional	
6634	33700001	Servicios para programas en materia de seguridad publica y nacional	Servicio
6635	33700002	Servicios de investigaciones en materia de seguridad publica y nacional	Servicio
6636	33700003	Servicio de recarga de extintor	Servicio
6637	33702	Gastos en actividades de seguridad y logistica del Estado Mayor Presidencial	
6638	33700004	Servicios de acciones en materia de seguridad publica y nacional	Servicio
6639	33700005	Servicios para actividades en materia de seguridad publica y nacional	Servicio
6640	3380	Servicios de vigilancia	
6641	33801	Servicios de vigilancia	
6642	33800001	Servicios de vigilancia de bienes inmuebles	Servicio
6643	3390	Servicios profesionales, cientificos y tecnicos integrales	
6644	33901	Subcontratacion de servicios con terceros	
6645	33900001	Estudios e investigaciones	Servicio
6646	33900002	Servicios estadisticos	Servicio
6647	33900003	Servicios estadisticos y geograficos	Servicio
6648	33900004	Servicios geograficos	Servicio
6649	33900005	Exploracion y evaluacion minera	Servicio
6650	33900006	Servicios de seguros de gastos medicos mayores	Servicio
6651	33900007	Servicio de estudios medicos	Servicio
6652	33900008	Servicio de estudios clinicos	Servicio
6653	33900009	Servicio hospitalario	Servicio
6654	33900010	Servicio medico	Servicio
6655	33900020	Servicio de elaboracion de productos institucionales de capacitacion	Servicio
6656	33900021	Servicio general de apoyo a la construccion naval	Servicio
6657	33900022	Reciclaje de residuos metalicos	Servicio
6658	33900023	Servicio de instalacion de letras corporeas	Servicio
6659	33900024	Servicio aduanero	Servicio
6660	33902	Proyectos para prestacion de servicios	
6661	33900011	Proyectos para prestacion de servicios	Servicio
6662	33903	Servicios integrales	
6663	33900012	Servicios integrales	Servicio
6664	33900013	Servicio de despacho y almacenamiento de combustibles	Servicio
6665	33900014	Servicio integral relacionado a la cuantificacion de inventarios	Servicio
6666	33900015	Servicio de estancia infantil	Servicio
6667	33900016	Servicio integral de licenciamiento e implementacion de software	Servicio
6668	33900017	Servicio de elaboracion e integracion de libros blancos	Servicio
6669	33904	Asignaciones derivadas de proyectos de asociacion publico privada	
6670	33905	Servicios integrales en materia de seguridad publica y nacional	
6671	33906	Asignaciones para cubrir el pago de obligaciones derivadas de titulos de concesion o de asignacion	
6672	3400	Servicios financieros, bancarios y comerciales	
6673	3410	Servicios financieros y bancarios	
6674	34101	Servicios bancarios y financieros	
6675	34100001	Servicio de avaluo o justipreciacion de bienes muebles	Servicio
6676	34100002	Servicios bancarios y financieros	Servicio
6677	3420	Servicios de cobranza, investigacion crediticia y similar	
6678	3430	Servicios de recaudacion, traslado y custodia de valores	
6679	34301	Gastos inherentes a la recaudacion	
6680	34300001	Servicios de recaudacion, traslado y custodia de valores	Servicio
6681	3440	Seguros de responsabilidad patrimonial y fianzas	
6682	34401	Seguros de responsabilidad patrimonial del Estado	
6683	34400001	Seguros de responsabilidad patrimonial	Servicio
6684	34400002	Fianzas	Servicio
6685	3450	Seguro de bienes patrimoniales	
6686	34501	Seguro de bienes patrimoniales	
6687	34500001	Contratacion de seguros para bienes muebles	Servicio
6688	34500002	Otros seguros de bienes patrimoniales	Servicio
6689	34500003	Seguro de inmuebles	Servicio
6690	34500004	Seguros contra incendios	Servicio
6691	34500005	Seguros contra robos	Servicio
6692	34500006	Seguro para aeronaves	Servicio
6693	3460	Almacenaje, envase y embalaje	
6694	34601	Seguro de bienes patrimoniales	
6695	34600001	Servicios de almacenaje de bienes muebles	Servicio
6696	34600002	Servicios de embalaje de bienes muebles	Servicio
6697	34600003	Servicios de envasado de bienes muebles	Servicio
6698	3470	Fletes y maniobras	
6699	34701	Fletes y maniobras	
6700	34700001	Fletes y acarreos de bienes muebles	Servicio
6701	34700002	Transporte aereo de bienes muebles	Servicio
6702	34700003	Transporte ferroviario de bienes muebles	Servicio
6703	34700004	Transporte maritimo de bienes muebles	Servicio
6704	34700005	Transporte terrestre no ferroviario de bienes muebles	Servicio
6705	3480	Comisiones por ventas	
6706	34801	Comisiones por ventas	
6707	3490	Servicios financieros, bancarios y comerciales integrales	
6708	3500	Servicios de instalacion, reparacion, mantenimiento y conservacion	
6709	3510	Conservacion y mantenimiento menor de inmuebles	
6710	35101	Mantenimiento y conservacion de inmuebles para la prestacion de servicios administrativos	
6711	35100001	Servicios de instalacion, reparacion, mantenimiento y conservacion menor de inmuebles	Servicio
6712	35102	Mantenimiento y conservacion de inmuebles para la prestacion de servicios publicos	
6713	35100003	Mantenimiento de inmuebles para la prestacion de servicios publicos	Servicio
6714	35100004	Conservacion de inmuebles para la prestacion de servicios publicos	Servicio
6715	3520	Instalacion, reparacion y mantenimiento de mobiliario y equipo de administracion, educacional y recreativo	
6716	35201	Mantenimiento y conservacion de mobiliario y equipo de administracion	
6717	35200001	Carpinteria y tapiceria de bienes muebles	Servicio
6718	35200003	Mobiliario y equipo de administracion (mantenimiento y reparacion)	Servicio
6719	35200004	Servicio de limpieza de mobiliario y equipo	Servicio
6720	35200005	Servicios de instalacion de mobiliario y equipo de administracion	Servicio
6721	35200006	Servicios de reparacion de mobiliario y equipo de administracion	Servicio
6722	35200007	Servicios de mantenimiento de mobiliario y equipo de administracion	Servicio
6723	3530	Instalacion, reparacion y mantenimiento de equipo de computo y tecnologia de la informacion	
6724	35301	Mantenimiento y conservacion de bienes informaticos	
6725	35300001	Servicio de mantenimiento, prevencion correccion y conservacion de equipo informatico	Servicio
6726	35300002	Actualizacion de software	Servicio
6727	3540	Instalacion, reparacion y mantenimiento de equipo e instrumental medico y de laboratorio	
6728	35401	Instalacion, reparacion y mantenimiento de equipo e instrumental medico y de laboratorio	
6729	35400001	Servicios de instalacion de equipo e instrumental medico	Servicio
6730	35400002	Servicios de reparacion de equipo e instrumental medico	Servicio
6731	35400003	Servicios de mantenimiento de equipo e instrumental medico	Servicio
6732	3550	Reparacion y mantenimiento de equipo de transporte	
6733	35501	Mantenimiento y conservacion de vehiculos terrestres, aereos, maritimos, lacustres y fluviales	
6734	35500001	Mantenimiento y conservacion de vehiculos aereos	Servicio
6735	35500002	Mantenimiento y conservacion de vehiculos fluviales	Servicio
6736	35500003	Mantenimiento y conservacion de vehiculos lacustres	Servicio
6737	35500004	Mantenimiento y conservacion de vehiculos maritimos	Servicio
6738	35500005	Mantenimiento y conservacion de vehiculos terrestres	Servicio
6739	3560	Reparacion y mantenimiento de equipo de defensa y seguridad	
6740	35601	Reparacion y mantenimiento de equipo de defensa y seguridad	
6741	35600001	Servicios de reparacion del equipo de defensa y seguridad	Servicio
6742	35600002	Servicios de mantenimiento del equipo de defensa y seguridad	Servicio
6743	3570	Instalacion, reparacion y mantenimiento de maquinaria, otros equipos y herramienta	
6744	35701	Mantenimiento y conservacion de maquinaria y equipo	
6745	35700001	Maquinaria y equipo (mantenimiento y reparacion)	Servicio
6746	35700002	Recarga de extintores	Servicio
6747	35702	Mantenimiento y conservacion de plantas e instalaciones productivas	
6748	35700003	Servicios de mantenimiento y conservacion de plantas e instalaciones productivas	Servicio
6749	3580	Servicios de limpieza y manejo de desechos	
6750	35801	Servicios de lavanderia, limpieza, higiene	
6751	35800001	Lavado y planchado	Servicio
6752	35800002	Servicios de desinfeccion	Servicio
6753	35800003	Servicios de higiene	Servicio
6754	35800004	Servicios de lavanderia	Servicio
6755	35800005	Servicios de recolecion, traslado y tratamiento final de desechos toxicos	Servicio
6756	3590	Servicios de jardineria y fumigacion	
6757	35901	Servicios de jardineria y fumigacion	
6758	35900001	Fumigacion de bienes muebles	Servicio
6759	35900002	Mantenimiento y conservacion de areas verdes (servicios)	Servicio
6760	35900003	Servicios de fumigacion	Servicio
6761	35900004	Servicios de jardineria	Servicio
6762	3600	Servicios de comunicacion social y publicidad	
6763	3610	Difusion por radio, television y otros medios de mensajes sobre programas y actividades gubernamentales	
6764	36101	Difusion de mensajes sobre programas y actividades gubernamentales	
6765	36100001	Difusion de mensajes sobre programas y actividades gubernamentales	Servicio
6766	36100002	Inserciones y publicaciones propias de la operacion de las dependencias y entidades que no formen parte de las campañas	Servicio
6767	3620	Difusion por radio, television y otros medios de mensajes comerciales para promover la venta de bienes o servicios	
6768	36201	Difusion de mensajes comerciales para promover la venta de productos o servicios	
6769	36200001	Gastos en publicidad de entidades que generan un ingreso para el estado	Servicio
6770	3630	Servicios de creatividad, preproduccion y produccion de publicidad, excepto Internet	
6771	36300001	Servicios de diseño y conceptualizacion de campañas de comunicacion	Servicio
6772	3640	Servicios de revelado de fotografias	
6773	36400001	Servicios de revelado de fotografias	Servicio
6774	36400002	Servicios de impresion de fotografias	Servicio
6775	36400003	Servicios de revelado e impresion de fotografias	Servicio
6776	3650	Servicios de la industria filmica, del sonido y del video	
6777	36500001	Servicios de industria filmica y del video	Servicio
6778	36500002	Servicios inherentes a la produccion de programas educativos	Servicio
6779	3660	Servicio de creacion y difusion de contenido exclusivamente a traves de Internet	
6780	36600001	Servicio de creacion y difusion de contenido exclusivamente a traves de Internet	Servicio
6781	3690	Otros servicios de informacion	
6782	36901	Servicios relacionados con monitoreo de informacion en medios masivos	
6783	36900001	Servicios de monitoreo de informacion	Servicio
6784	3700	Servicios de traslado y viaticos	
6785	3710	Pasajes aereos	
6786	37101	Pasajes aereos nacionales para labores en campo y de supervision	
6787	37100003	Pasajes aereos nacionales para labores en campo y de supervision	Servicio
6788	37102	Pasajes aereos nacionales asociados a los programas de seguridad publica y nacional	
6789	37100004	Pasajes aereos nacionales asociados a los programas de seguridad publica y nacional	Servicio
6790	37103	Pasajes aereos nacionales asociados a desastres naturales	
6791	37100005	Pasajes aereos nacionales asociados a desastres naturales	Servicio
6792	37104	Pasajes aereos nacionales para servidores publicos de mando en el desempeño de comisiones y funciones oficiales	
6793	37100006	Pasajes aereos nacionales para servidores publicos de mando en el desempeño de comisiones y funciones oficiales	Servicio
6794	37105	Pasajes aereos internacionales asociados a los programas de seguridad publica y nacional	
6795	37100001	Pasajes internacionales asociados a los programas de seguridad publica y nacional	Servicio
6796	37106	Pasajes aereos internacionales para servidores publicos en el desempeño de comisiones y funciones oficiales	
6797	39904	Participaciones en Organos de Gobierno	
6798	51100101	Sillon	Pieza
6799	37100002	Pasajes internacionales para servidores publicos en el desempeño de comisiones y funciones oficiales	Servicio
6800	3720	Pasajes terrestres	
6801	37201	Pasajes terrestres nacionales para labores en campo y de supervision	
6802	37200001	Pasajes nacionales para labores en campo y de supervision	Servicio
6803	37202	Pasajes terrestres nacionales asociados a los programas de seguridad publica y nacional	
6804	37200002	Pasajes nacionales asociados a los programas de seguridad publica y nacional	Servicio
6805	37203	Pasajes terrestres nacionales asociados a desastres naturales	
6806	37200003	Pasajes nacionales asociados a desastres naturales	Servicio
6807	37204	Pasajes terrestres nacionales para servidores publicos de mando en el desempeño de comisiones y funciones oficiales	
6808	37200004	Pasajes nacionales para servidores publicos de mando en el desempeño de comisiones y funciones oficiales	Servicio
6809	37205	Pasajes terrestres internacionales asociados a los programas de seguridad publica y nacional	
6810	37200005	Pasajes terrestres internacionales asociados a los programas de seguridad publica y nacional	Servicio
6811	37206	Pasajes terrestres internacionales para servidores publicos en el desempeño de comisiones y funciones oficiales	
6812	37200006	Pasajes terrestres internacionales para servidores publicos en el desempeño de comisiones y funciones oficiales	Servicio
6813	37207	Pasajes terrestres nacionales por medio electronico	
6814	37200007	Pasajes en transporte urbano de servidores publicos (con transaccion electronica)	Servicio
6815	37200008	Pasajes en transporte suburbano de servidores publicos (con transaccion electronica)	Servicio
6816	3730	Pasajes maritimos, lacustres y fluviales	
6817	37301	Pasajes maritimos, lacustres y fluviales para labores en campo y de supervision	
6818	37302	Pasajes maritimos, lacustres y fluviales asociados a los programas de seguridad publica y nacional	
6819	37303	Pasajes maritimos, lacustres y fluviales asociados a desastres naturales	
6820	37304	Pasajes maritimos, lacustres y fluviales para servidores publicos de mando en el desempeño de comisiones y funciones oficiales	
6821	3740	Autotransporte	
6822	3750	Viaticos en el pais	
6823	37501	Viaticos nacionales para labores en campo y de supervision	
6824	37502	Viaticos nacionales asociados a los programas de seguridad publica y nacional	
6825	37503	Viaticos nacionales asociados a desastres naturales	
6826	37504	Viaticos nacionales para servidores publicos en el desempeño de funciones oficiales	
6827	3760	Viaticos en el extranjero	
6828	37601	Viaticos en el extranjero asociados a los programas de seguridad publica y nacional	
6829	37602	Viaticos en el extranjero para servidores publicos en el desempeño de comisiones y funciones oficiales	
6830	3770	Gastos de instalacion y traslado de menaje	
6831	37701	Instalacion del personal federal	
6832	37700002	Traslado de menaje de casa	Servicio
6833	3780	Servicios integrales de traslado y viaticos	
6834	37801	Servicios integrales nacionales para servidores publicos en el desempeño de comisiones y funciones oficiales	
6835	37802	Servicios integrales en el extranjero para servidores publicos en el desempeño de comisiones y funciones oficiales	
6836	3790	Otros servicios de traslado y hospedaje	
6837	37901	Gastos para operativos y trabajos de campo en areas rurales	
6838	3800	Servicios oficiales	
6839	3810	Gastos de ceremonial	
6840	38101	Gastos de ceremonial del titular del Ejecutivo Federal	
6841	38102	Gastos de ceremonial de los titulares de las dependencias y entidades	
6842	38103	Gastos inherentes a la investidura presidencial	
6843	3820	Gastos de orden social y cultural	
6844	38201	Gastos de orden social	
6845	38200001	Gastos de orden social	Servicio
6846	38200002	Elaboracion de piezas conmemorativas	Servicio
6847	3830	Congresos y convenciones	
6848	38301	Congresos y convenciones	
6849	38300001	Congresos y convenciones	Servicio
6850	3840	Exposiciones	
6851	38401	Exposiciones	
6852	38400001	Exposiciones	Servicio
6853	3850	Gastos de representacion	
6854	38501	Gastos para alimentacion de servidores publicos de mando	
6855	3900	Otros servicios generales	
6856	3910	Servicios funerarios y de cementerios	
6857	39101	Funerales y pagas de defuncion	
6858	39100001	Servicios funerarios (defuncion, traslado de cuerpos, velacion, cremacion, embalsamamiento y ataudes)	Servicio
6859	3920	Impuestos y derechos	
6860	39201	Impuestos y derechos de exportacion	
6861	39202	Otros impuestos y derechos	
6862	3930	Impuestos y derechos de importacion	
6863	39301	Impuestos y derechos de importacion	
6864	3940	Sentencias y resoluciones judiciales	
6865	39401	Erogaciones por resoluciones por autoridad competente	
6866	39402	Indemnizaciones por expropiacion de predios	
6867	39403	Otras asignaciones derivadas de resoluciones de ley	
6868	3950	Penas, multas, accesorios y actualizaciones	
6869	39501	Penas, multas, accesorios y actualizaciones	
6870	3960	Otros gastos por responsabilidades	
6871	39601	Perdidas del erario federal	
6872	39602	Otros gastos por responsabilidades	
6873	39602001	Seguro de vida	
6874	39602002	Seguro de responsabilidad civil y asistencia legal	
6875	3970	Utilidades	
6876	39701	Erogaciones por concepto de utilidades	
6877	3980	Impuesto sobre nominas y otros que se deriven de una relacion laboral	
6878	39801	Impuesto sobre nominas	
6879	3990	Otros servicios generales	
6880	39901	Gastos de las Comisiones Internacionales de Limites y Aguas	
6881	39902	Gastos de las oficinas del Servicio Exterior Mexicano	
6882	39903	Asignaciones a los grupos parlamentarios	
6883	39905	Actividades de Coordinacion con el Presidente Electo	
6884	39906	Servicios Corporativos prestados por las Entidades Paraestatales a sus Organismos	
6885	39907	Servicios prestados entre Organismos de una Entidad Paraestatal	
6886	39908	Erogaciones por cuenta de terceros	
6887	39909	Erogaciones recuperables	
6888	39910	Apertura de Fondo Rotatorio	
6889	5000	Bienes muebles, e intangibles	
6890	5100	Mobiliario y equipo de administracion	
6891	5110	Muebles de oficina y estanteria	
6892	51101	Mobiliario	
6893	51100001	Anaquel movil	Pieza
6894	51100002	Anaquel para indices medicos (equipo medico quirurgico)	Pieza
6895	51100003	Apartado postal	Pieza
6896	51100004	Archivero	Pieza
6897	51100005	Archivero de madera	Pieza
6898	51100006	Archivero de metal	Pieza
6899	51100007	Archivero guarda visible	Pieza
6900	51100008	Arcos de seguridad para biblioteca (detecta libros)	Pieza
6901	51100009	Banca	Pieza
6902	51100010	Banco	Pieza
6903	51100011	Banco combinados (madera y metal)	Pieza
6904	51100012	Banco de madera	Pieza
6905	51100013	Banco fijo	Pieza
6906	51100014	Banco giratorio	Pieza
6907	51100015	Bancos de metal	Pieza
6908	51100016	Base caja fuerte	Pieza
6909	51100017	Base poste y cordon para una sola fila (elemento arq. para exposicion)	Pieza
6910	51100018	Butaca	Pieza
6911	51100019	Contra escritorio	Pieza
6912	51100020	Credenza	Pieza
6913	51100021	Cubierta metalica para mueble	Pieza
6914	51100022	Escritorio	Pieza
6915	51100023	Escritorio de madera	Pieza
6916	51100024	Escritorio de metal	Pieza
6917	51100025	Estante	Pieza
6918	51100026	Estudio couch	Pieza
6919	51100027	Gabinete kardex	Pieza
6920	51100028	Gabinete llaves	Pieza
6921	51100029	Gabinete para archivo	Pieza
6922	51100030	Gabinete para letra transferible	Pieza
6923	51100031	Gabinete para toma de muestras laboratorio (equipo medico quirurgico)	Pieza
6924	51100032	Gabinete telefonico	Pieza
6925	51100033	Gabinete universal	Pieza
6926	51100034	Gaveta archivadora	Pieza
6927	51100035	Gaveta papelera	Pieza
6928	51100036	Librero	Pieza
6929	51100037	Librero de madera	Pieza
6930	51100038	Librero de metal	Pieza
6931	51100039	Locker/casillero	Pieza
6932	51100040	Mesa	Pieza
6933	51100041	Mesa auxiliar	Pieza
6934	51100042	Mesa auxiliar de madera	Pieza
6935	51100043	Mesa auxiliar de metal	Pieza
6936	51100044	Mesa auxiliar de plastico	Pieza
6937	51100045	Mesa banco	Pieza
6938	51100046	Mesa banco (madera metal)	Pieza
6939	51100047	Mesa banco de madera	Pieza
6940	51100048	Mesa banco de metal	Pieza
6941	51100049	Mesa banco de plastico	Pieza
6942	51100050	Mesa caliente para gas o vapor	Pieza
6943	51100051	Mesa combinada  madera y metal	Pieza
6944	51100052	Mesa de centro	Pieza
6945	51100053	Mesa de centro de madera	Pieza
6946	51100054	Mesa de centro de metal	Pieza
6947	51100055	Mesa de centro de plastico	Pieza
6948	51100056	Mesa de juntas	Pieza
6949	51100057	Mesa de juntas de madera	Pieza
6950	51100058	Mesa de juntas de metal	Pieza
6951	51100059	Mesa de juntas de plastico	Pieza
6952	51100060	Mesa de madera	Pieza
6953	51100061	Mesa de metal	Pieza
6954	51100062	Mesa de trabajo	Pieza
6955	51100063	Mesa de trabajo de madera	Pieza
6956	51100064	Mesa de trabajo de metal	Pieza
6957	51100065	Mesa de trabajo de plastico	Pieza
6958	51100066	Mesa electrica caliente movil	Pieza
6959	51100067	Mesa esquinera	Pieza
6960	51100068	Mesa esquinera de madera	Pieza
6961	51100069	Mesa esquinera de metal	Pieza
6962	51100070	Mesa esquinera de plastico	Pieza
6963	51100071	Mesa fria a hielo movil	Pieza
6964	51100072	Mesa fria para barra de autoservicio	Pieza
6965	51100073	Mesa mayo porta instrumental (equipo medico quirurgico)	Pieza
6966	51100074	Mesa puente con cremallera (equipo medico quirurgico)	Pieza
6967	51100075	Mesa puente sin cremallera (equipo medico quirurgico)	Pieza
6968	51100076	Mesa-escritorio suspendida o con soportes	Pieza
6969	51100077	Modulo desarmable	Pieza
6970	51100078	Mueble exhibidor de revistas	Pieza
6971	51100079	Mueble mostrador para atencion al publico	Pieza
6972	51100080	Nicho bandera	Pieza
6973	51100081	Pedestal movil	Pieza
6974	51100082	Perchero	Pieza
6975	51100083	Perchero de madera	Pieza
6976	51100084	Perchero de metal	Pieza
6977	51100085	Portamapa	Pieza
6978	51100086	Pupitre	Pieza
6979	51100087	Repisa	Pieza
6980	51100088	Revistero	Pieza
6981	51100089	Rotafolio	Pieza
6982	51100090	Silla	Pieza
6983	51100091	Silla cama para toma de muestras (equipo medico quirurgico)	Pieza
6984	51100092	Silla de madera	Pieza
6985	51100093	Silla de metal	Pieza
6986	51100094	Silla giratoria	Pieza
6987	51100095	Silla infantil	Pieza
6988	51100096	Silla infantil de madera	Pieza
6989	51100097	Silla infantil de metal	Pieza
6990	51100098	Silla infantil de plastico	Pieza
6991	51100099	Silla porta bebe	Pieza
6992	51100100	Sillas de paleta	Pieza
6993	51100102	Sillon  de pedicure	Pieza
6994	51100103	Sillon lavabo (lavacabezas)	Pieza
6995	51100104	Sillon tijera	Pieza
6996	51100105	Tarjetero de metal	Pieza
6997	51100106	Tripie	Pieza
6998	51100107	Tripie para pizarron	Pieza
6999	51100108	Sillon infantil amoldable (puff)	Pieza
7000	51100109	Mueble o torre porta cd, dvd o blu ray todo material y capacidad	Pieza
7001	51100110	Climazon de pared o pedestal	Pieza
7002	51100111	Anaqueles	Pieza
7003	51100112	Caja archivadora	Pieza
7004	51100113	Bebedero de pared	Pieza
7005	5120	Muebles, excepto de oficina y estanteria	
7006	51201	Muebles, excepto de oficina y estanteria	
7007	51200001	Biombo	Pieza
7008	51200002	Cabina con aislamiento acustico y amortiguacion de sonido	Pieza
7009	51200003	Camilla portatil para terapia	Pieza
7010	51200004	Canape o divan	Pieza
7011	51200005	Cantina	Pieza
7012	51200006	Carrito pedales	Pieza
7013	51200007	Carro cajonero (peine) (equipo medico quirurgico)	Pieza
7014	51200008	Carro distribucion de muestras (equipo medico quirurgico)	Pieza
7015	51200009	Carro para material y equipo (equipo medico quirurgico)	Pieza
7016	51200010	Carro para ropa limpia (equipo medico quirurgico)	Pieza
7017	51200011	Carro transportador de biberones	Pieza
7018	51200012	Carro transportador de libros	Pieza
7019	51200013	Carro transportador de ropa humeda	Pieza
7020	51200014	Carro transportador de ropa limpia	Pieza
7021	51200015	Carro transportador de ropa sucia	Pieza
7022	51200016	Carro transportar billetes	Pieza
7023	51200017	Carro transportar cintas	Pieza
7024	51200018	Carro transportar papeleria	Pieza
7025	51200019	Catafalco (eq. para comercios)	Pieza
7026	51200020	Catre (eq. deportivo o de campaña)	Pieza
7027	51200021	Consola para intercomunicacion (eq. electrico)	Pieza
7028	51200022	Deposito para pan autoservicio (eq. para comercios)	Pieza
7029	51200023	Juguetero	Pieza
7030	51200024	Juguetero de madera	Pieza
7031	51200025	Juguetero de metal	Pieza
7032	51200026	Juguetero de plastico	Pieza
7033	51200027	Lampara de cabecera (eq. electrico)	Pieza
7034	51200028	Pizarron electronico	Pieza
7035	51200029	Pizarrones de madera	Pieza
7036	51200030	Pizarrones de metal	Pieza
7037	51200031	Sofa	Pieza
7038	51200032	Taburete	Pieza
7039	51200033	Tarimas para escenario modular (elemento arq. para exposicion)	Pieza
7040	5130	Bienes artisticos, culturales y cientificos	
7041	51301	Bienes artisticos y culturales	
7042	51300001	Acetre (objeto liturgico para exposicion)	Pieza
7043	51300002	Acordeon (inst. Musical)	Pieza
7044	51300003	Aguamanil (juego de lavamanos) (objeto liturgico para exposicion)	Pieza
7045	51300004	Alacena (objeto liturgico para exposicion)	Pieza
7046	51300005	Album (para exposicion)	Pieza
7047	51300006	Alfarda o remate (elemento arq. Para exposicion)	Pieza
7048	51300007	Almena o remate (elemento arq. Para exposicion)	Pieza
7049	51300008	Altar (elemento arq. Para exposicion)	Pieza
7050	51300009	Anillo de oro (para exposicion)	Pieza
7051	51300010	Animales disecados (coleccion de) (para exposicion)	Pieza
7052	51300011	Animales vivos (coleccion de) (para exposicion)	Pieza
7053	51300012	Aparato para determinar la resistencia del papel (objeto liturgico para exposicion)	Pieza
7054	51300013	Arandela (objeto liturgico para exposicion)	Pieza
7055	51300014	Archivero (objeto liturgico para exposicion)	Pieza
7056	51300015	Arcon (objeto liturgico para exposicion)	Pieza
7057	51300016	Armonica (inst. Musical)	Pieza
7058	51300017	Armonio (inst. Musical)	Pieza
7059	51300018	Aro juego pelota (elemento arq. Para exposicion)	Pieza
7060	51300019	Arpa (inst. Musical)	Pieza
7061	51300020	Arreos masonicos (mandil, collarin y banda) (para exposicion)	Pieza
7062	51300021	Atril (objeto liturgico para exposicion)	Pieza
7063	51300022	Automovil (objeto liturgico para exposicion)	Pieza
7064	51300023	Bajo (inst. Musical)	Pieza
7065	51300024	Balaustrada, barandal, baranda (elemento arq. Para exposicion)	Pieza
7066	51300025	Baldaquino (objeto liturgico para exposicion)	Pieza
7067	51300026	Banderas y astas (coleccion de) (para exposicion)	Pieza
7068	51300027	Banqueta (elemento arq. Para exposicion)	Pieza
7069	51300028	Banqueta (objeto liturgico para exposicion)	Pieza
7070	51300029	Bargueño (objeto liturgico para exposicion)	Pieza
7071	51300030	Baritono flauta (inst. Musical)	Pieza
7072	51300031	Basamento (elemento arq. Para exposicion)	Pieza
7073	51300033	Base bracero (elemento arq. Para exposicion)	Pieza
7074	51300034	Baul (objeto liturgico para exposicion)	Pieza
7075	51300035	Biombo (objeto liturgico para exposicion)	Pieza
7076	51300036	Bloque (elemento arq. Para exposicion)	Pieza
7077	51300037	Bombo (inst. Musical)	Pieza
7078	51300038	Bongo (inst. Musical)	Pieza
7079	51300039	Bosquejo (para exposicion)	Pieza
7080	51300040	Bugle (inst. Musical)	Pieza
7081	51300041	Buro (objeto liturgico para exposicion)	Pieza
7082	51300042	Caballete (objeto liturgico para exposicion)	Pieza
7083	51300043	Caja decorativa (para exposicion)	Pieza
7084	51300044	Caja fuerte (objeto liturgico para exposicion)	Pieza
7085	51300045	Caliz (objeto liturgico para exposicion)	Pieza
7086	51300046	Cama (objeto liturgico para exposicion)	Pieza
7087	51300047	Campanas tubulares (inst. Musical)	Pieza
7088	54100047	Funicular	Pieza
7089	51300048	Candelabro (objeto liturgico para exposicion)	Pieza
7090	51300049	Candelero (objeto liturgico para exposicion)	Pieza
7091	51300050	Candil (objeto liturgico para exposicion)	Pieza
7092	51300051	Capitel (elemento arq. Para exposicion)	Pieza
7093	51300052	Carpeta de oracion (para exposicion)	Pieza
7094	51300053	Carriola (objeto liturgico para exposicion)	Pieza
7095	51300054	Casco samurai (para exposicion)	Pieza
7096	51300055	Cassette y cartucho (procesados) (para exposicion)	Pieza
7097	51300056	Catalogo (para exposicion)	Pieza
7098	51300057	Celesta (inst. Musical)	Pieza
7099	51300058	Cello (inst. Musical)	Pieza
7100	51300059	Celosia (elemento arq. Para exposicion)	Pieza
7101	51300060	Cencerro (inst. Musical)	Pieza
7102	51300061	Cerrojo (para exposicion)	Pieza
7103	51300062	Cesto de basura (objeto liturgico para exposicion)	Pieza
7104	51300063	Charango (inst. Musical)	Pieza
7105	51300064	Cinta magnetica procesada (para exposicion)	Pieza
7106	51300065	Cinta magnetofonica procesada (para exposicion)	Pieza
7107	51300066	Citara (inst. Musical)	Pieza
7108	51300067	Clarin (inst. Musical)	Pieza
7109	51300068	Clarinete (inst. Musical)	Pieza
7110	51300069	Clavecin (inst. Musical)	Pieza
7111	51300070	Codice (para exposicion)	Pieza
7112	51300071	Cofre de caudales (objeto liturgico para exposicion)	Pieza
7113	51300072	Cojin (objeto liturgico para exposicion)	Pieza
7114	51300073	Colage (para exposicion)	Pieza
7115	51300074	Coleccion de espuelas (para exposicion)	Pieza
7116	51300075	Colecciones varias (para exposicion)	Pieza
7117	51300076	Colmillo de elefante (para exposicion)	Pieza
7118	51300077	Columna (elemento arquitectonico) (elemento arq. Para exposicion)	Pieza
7119	51300078	Comoda (objeto liturgico para exposicion)	Pieza
7120	51300079	Consola (objeto liturgico para exposicion)	Pieza
7121	51300080	Contrabajo (inst. Musical)	Pieza
7122	51300081	Copon (objeto liturgico para exposicion)	Pieza
7123	51300082	Cornisa (elemento arq. Para exposicion)	Pieza
7124	51300083	Corno frances (inst. Musical)	Pieza
7125	51300084	Corno ingles (inst. Musical)	Pieza
7126	51300085	Costurero (objeto liturgico para exposicion)	Pieza
7127	51300086	Credenza (objeto liturgico para exposicion)	Pieza
7128	51300087	Crotalos (inst. Musical)	Pieza
7129	51300088	Crucifijo (objeto liturgico para exposicion)	Pieza
7130	51300089	Cuatricordio (inst. Musical)	Pieza
7131	51300090	Cubre caliz (objeto liturgico para exposicion)	Pieza
7132	51300091	Custodia (objeto liturgico para exposicion)	Pieza
7133	51300092	Destilador para analisis de muestra del petroleo (objeto liturgico para exposicion)	Pieza
7134	51300093	Dibujo (a tinta, lapiz, carbon, crayon, crayola, gis) (para exposicion)	Pieza
7135	51300094	Dintel (elemento arq. Para exposicion)	Pieza
7136	51300095	Disco magnetico procesado (para exposicion)	Pieza
7137	51300096	Disco magnetofonico procesado (para exposicion)	Pieza
7138	51300097	Documento aislado (para exposicion)	Pieza
7139	51300098	Escabel (objeto liturgico para exposicion)	Pieza
7140	51300099	Escritorio (objeto liturgico para exposicion)	Pieza
7141	51300100	Escudos heraldicos (coleccion de) (para exposicion)	Pieza
7142	51300101	Escultura (para exposicion)	Pieza
7143	51300102	Escultura al alto relieve (para exposicion)	Pieza
7144	51300103	Escultura al bajo relieve (para exposicion)	Pieza
7145	51300104	Escultura de volumen (para exposicion)	Pieza
7146	51300105	Escupidera (para exposicion)	Pieza
7147	51300106	Esfera geografica (para exposicion)	Pieza
7148	51300107	Espejo (objeto liturgico para exposicion)	Pieza
7149	51300108	Espiguero metalico (objeto liturgico para exposicion)	Pieza
7150	51300109	Esqueleto humano y partes oseas (para exposicion)	Pieza
7151	51300110	Estela (elemento arq. Para exposicion)	Pieza
7152	51300111	Estudio (para exposicion)	Pieza
7153	51300112	Expediente (para exposicion)	Pieza
7154	51300113	Fagot (inst. Musical)	Pieza
7155	51300114	Faldistorio (objeto liturgico para exposicion)	Pieza
7156	51300115	Figura de bronce (para exposicion)	Pieza
7157	51300116	Figura de marfil (para exposicion)	Pieza
7158	51300117	Filmina o diapositiva (fuente documental) (para exposicion)	Pieza
7159	51300118	Flauta (inst. Musical)	Pieza
7160	51300119	Florero (para exposicion)	Pieza
7161	51300120	Fotografia (fuente documental) (para exposicion)	Pieza
7162	51300121	Frasco (para exposicion)	Pieza
7163	51300122	Friso (elemento arq. Para exposicion)	Pieza
7164	51300123	Fuente documental procesada (para exposicion)	Pieza
7165	51300124	Funda para maquina con cortina (objeto liturgico para exposicion)	Pieza
7166	51300125	Fuste (elemento arq. Para exposicion)	Pieza
7167	51300126	Gargola (elemento arq. Para exposicion)	Pieza
7168	51300127	Glifo (elemento arq. Para exposicion)	Pieza
7169	51300128	Gobelino (para exposicion)	Pieza
7170	51300129	Gong (inst. Musical)	Pieza
7171	51300130	Grabado (en papel) (para exposicion)	Pieza
7172	51300131	Grabado sobre metal  (para exposicion)	Pieza
7173	51300132	Guion (para exposicion)	Pieza
7174	51300133	Guitarra (inst. Musical)	Pieza
7175	51300134	Guitarra electrica (inst. Musical)	Pieza
7176	51300135	Hacha votiva (objeto liturgico para exposicion)	Pieza
7177	51300136	Heckelfono (inst. Musical)	Pieza
7178	51300137	Hisopo (objeto liturgico para exposicion)	Pieza
7179	51300138	Horno de mufla para fundir metales (objeto liturgico para exposicion)	Pieza
7180	51300139	Icono (para exposicion)	Pieza
7181	51300140	Incensario (objeto liturgico para exposicion)	Pieza
7182	51300141	Incensario de bronce (para exposicion)	Pieza
7183	51300142	Intercomunicador (objeto liturgico para exposicion)	Pieza
7184	51300143	Jabonera (para exposicion)	Pieza
7185	51300144	Jamba (elemento arq. Para exposicion)	Pieza
7186	51300145	Jarana (inst. Musical)	Pieza
7187	51300146	Jarron (para exposicion)	Pieza
7188	51300147	Jaula (para exposicion)	Pieza
7189	51300148	Juego de mesa (cartas) (para exposicion)	Pieza
7190	51300149	Juego de pesas y contrapesas (para exposicion)	Pieza
7191	51300150	Juguetero (objeto liturgico para exposicion)	Pieza
7192	51300151	Ladrillo (elemento arq. Para exposicion)	Pieza
7193	51300152	Lampara de mesa (objeto liturgico para exposicion)	Pieza
7194	51300153	Lampara de pista (objeto liturgico para exposicion)	Pieza
7195	51300154	Lampara votiva (objeto liturgico para exposicion)	Pieza
7196	51300155	Lapida (elemento arq. Para exposicion)	Pieza
7197	51300156	Laud (inst. Musical)	Pieza
7198	51300157	Librero (objeto liturgico para exposicion)	Pieza
7199	51300158	Libro (para exposicion)	Pieza
7200	51300159	Litografia (para exposicion)	Pieza
7201	51300160	Maceta (para exposicion)	Pieza
7202	51300161	Mandolina (inst. Musical)	Pieza
7203	51300162	Mantequillera, salero o tenedor (para exposicion)	Pieza
7204	51300163	Manton de manila (para exposicion)	Pieza
7205	51300164	Manual o instructivo (para exposicion)	Pieza
7206	51300165	Mapa (para exposicion)	Pieza
7207	51300166	Maqueta (para exposicion)	Pieza
7208	51300167	Maquina calculadora electrica (objeto liturgico para exposicion)	Pieza
7209	51300168	Maquina de escribir electrica (objeto liturgico para exposicion)	Pieza
7210	51300169	Maquina de escribir mecanica (objeto liturgico para exposicion)	Pieza
7211	51300170	Maquina protectora de cheques (objeto liturgico para exposicion)	Pieza
7212	51300171	Maquina registradora (objeto liturgico para exposicion)	Pieza
7213	51300172	Maquina sumadora manual y electrica (objeto liturgico para exposicion)	Pieza
7214	51300173	Maracas (inst. Musical)	Pieza
7215	51300174	Marco (para exposicion)	Pieza
7216	51300175	Marimba (inst. Musical)	Pieza
7217	51300176	Medalla (para exposicion)	Pieza
7218	51300177	Mesa (objeto liturgico para exposicion)	Pieza
7219	51300178	Mesa de ornato (objeto liturgico para exposicion)	Pieza
7220	51300179	Microfilm (fuente documental) (para exposicion)	Pieza
7221	51300180	Minerales (coleccion de) (para exposicion)	Pieza
7222	51300181	Misal (objeto liturgico para exposicion)	Pieza
7223	51300182	Moldura (elemento arq. Para exposicion)	Pieza
7224	51300183	Molino para cafe (objeto liturgico para exposicion)	Pieza
7225	51300184	Monedas o billetes (coleccion de) (para exposicion)	Pieza
7226	51300185	Mosqueton (objeto liturgico para exposicion)	Pieza
7227	51300186	Motocicleta (objeto liturgico para exposicion)	Pieza
7228	51300187	Mueble tarjetero (objeto liturgico para exposicion)	Pieza
7229	51300188	Naveta (objeto liturgico para exposicion)	Pieza
7230	51300189	Nicho (para exposicion)	Pieza
7231	51300190	Nicho para bandera (objeto liturgico para exposicion)	Pieza
7232	51300191	Oboe (inst. Musical)	Pieza
7233	51300192	Organo (inst. Musical)	Pieza
7234	51300193	Organo de fuelle (objeto liturgico para exposicion)	Pieza
7235	51300194	Palia-cubre hostia (objeto liturgico para exposicion)	Pieza
7236	51300195	Palmatoria (objeto liturgico para exposicion)	Pieza
7237	51300196	Pandero (inst. Musical)	Pieza
7238	51300197	Partitura (para exposicion)	Pieza
7239	51300198	Patena (objeto liturgico para exposicion)	Pieza
7240	51300199	Peana (elemento arq. Para exposicion)	Pieza
7241	51300200	Pedestal especial (objeto liturgico para exposicion)	Pieza
7242	51300201	Pedestal soporte ataud (objeto liturgico para exposicion)	Pieza
7243	51300202	Pelicula (fuente documental) (para exposicion)	Pieza
7244	51300203	Perchero (objeto liturgico para exposicion)	Pieza
7245	51300204	Perforadora (objeto liturgico para exposicion)	Pieza
7246	51300205	Periodicos y revistas (coleccion de) (para exposicion)	Pieza
7247	51300206	Piano (inst. Musical)	Pieza
7248	51300207	Pianola (inst. Musical)	Pieza
7249	51300208	Pilastra (elemento arq. Para exposicion)	Pieza
7250	51300209	Pintura mural (para exposicion)	Pieza
7251	51300210	Pintura mural acrilica (para exposicion)	Pieza
7252	51300211	Pintura mural al fresco (para exposicion)	Pieza
7253	51300212	Pintura mural al oleo (para exposicion)	Pieza
7254	51300213	Pintura mural al seco (para exposicion)	Pieza
7255	51300214	Pintura mural al temple (para exposicion)	Pieza
7256	51300215	Pintura mural encaustica (para exposicion)	Pieza
7257	51300216	Pintura mural grisalla (para exposicion)	Pieza
7258	51300217	Pinturas (para exposicion)	Pieza
7259	51300218	Placa (elemento arq. Para exposicion)	Pieza
7260	51300219	Plantas (coleccion de) (para exposicion)	Pieza
7261	51300220	Platillos (inst. Musical)	Pieza
7262	51300221	Plato (para exposicion)	Pieza
7263	51300222	Plato petitorio (objeto liturgico para exposicion)	Pieza
7264	51300223	Porta hilos (para exposicion)	Pieza
7265	51300224	Porta retrato (para exposicion)	Pieza
7266	51300225	Prensa para insertar buhes (objeto liturgico para exposicion)	Pieza
7267	51300226	Programas, sistemas computo (para exposicion)	Pieza
7268	51300227	Quinque (objeto liturgico para exposicion)	Pieza
7269	51300228	Reclinatorio (objeto liturgico para exposicion)	Pieza
7270	51300229	Redoba o caja de sonido por percusion (inst. Musical)	Pieza
7271	51300230	Reja de proteccion para ventanilla de atencion al publico (elemento arq. Para exposicion)	Pieza
7272	51300231	Reloj de bolsillo (para exposicion)	Pieza
7273	51300232	Reloj mueble (objeto liturgico para exposicion)	Pieza
7274	51300233	Remalladora de medias (objeto liturgico para exposicion)	Pieza
7275	51300234	Requinto (instrumento musical) (inst. Musical)	Pieza
7276	51300235	Retablo (elemento arq. Para exposicion)	Pieza
7277	51300236	Ropero (objeto liturgico para exposicion)	Pieza
7278	51300237	Rosario (objeto liturgico para exposicion)	Pieza
7279	51300238	Rueca (objeto liturgico para exposicion)	Pieza
7280	51300239	Sacra (objeto liturgico para exposicion)	Pieza
7281	51300240	Salterio (inst. Musical)	Pieza
7282	51300241	Saxofon (inst. Musical)	Pieza
7283	51300242	Secreter (objeto liturgico para exposicion)	Pieza
7284	51300243	Sello postal, oficial, lacrar (coleccion de) (para exposicion)	Pieza
7285	51300244	Silla (objeto liturgico para exposicion)	Pieza
7286	51300245	Silla de montar (objeto liturgico para exposicion)	Pieza
7287	51300246	Silla en madera de machiche (objeto liturgico para exposicion)	Pieza
7288	51300247	Sillon (objeto liturgico para exposicion)	Pieza
7289	51300248	Sinfonola (objeto liturgico para exposicion)	Pieza
7290	51300249	Sofa (objeto liturgico para exposicion)	Pieza
7291	51300250	Soporte cedulario (objeto liturgico para exposicion)	Pieza
7292	51300251	Soporte para tambores musical (soporte de redoblantes) (inst. Musical)	Pieza
7293	51300252	Sordina para trompeta (inst. Musical)	Pieza
7294	51300253	Tabernaculo (objeto liturgico para exposicion)	Pieza
7295	51300254	Taburete (objeto liturgico para exposicion)	Pieza
7296	51300255	Tambor (inst. Musical)	Pieza
7297	51300256	Tapete alfombra (objeto liturgico para exposicion)	Pieza
7298	51300257	Tapiz pintura (para exposicion)	Pieza
7299	51300258	Tarjetas perforadas (para exposicion)	Pieza
7300	51300259	Tarola bateria (inst. Musical)	Pieza
7301	51300260	Timbal (inst. Musical)	Pieza
7302	51300261	Tinaja (objeto liturgico para exposicion)	Pieza
7303	51300262	Tomtom (inst. Musical)	Pieza
7304	51300263	Torchero metalico (objeto liturgico para exposicion)	Pieza
7305	51300264	Tortilladora manual (objeto liturgico para exposicion)	Pieza
7306	51300265	Triangulo (inst. Musical)	Pieza
7307	51300266	Trinchador (objeto liturgico para exposicion)	Pieza
7308	51300267	Trinchador miniatura (juguete) (objeto liturgico para exposicion)	Pieza
7309	51300268	Trofeos (coleccion de) (para exposicion)	Pieza
7310	51300269	Trombon (inst. Musical)	Pieza
7311	51300270	Trompeta (inst. Musical)	Pieza
7312	51300271	Trono (elemento arq. Para exposicion)	Pieza
7313	51300272	Tuba (inst. Musical)	Pieza
7314	51300273	Vibrafono (inst. Musical)	Pieza
7315	51300274	Vihuela (inst. Musical)	Pieza
7316	51300275	Vinajera (objeto liturgico para exposicion)	Pieza
7317	51300276	Viola (inst. Musical)	Pieza
7318	51300277	Violin (inst. Musical)	Pieza
7319	51300278	Violonchelo (inst. musical)	Pieza
7320	51300279	Vitral (elemento arq. Para exposicion)	Pieza
7321	51300280	Vitrina central (objeto liturgico para exposicion)	Pieza
7322	51300281	Vitrina modular (objeto liturgico para exposicion)	Pieza
7323	51300282	Xilofono (inst. Musical)	Pieza
7324	51300283	Zoclo (elemento arq. Para exposicion)	Pieza
7325	51300284	Maquina productora de hielo frappe	Pieza
7326	51300285	Porta conos de todo material y capacidad	Pieza
7327	51300286	Cono imhoff de todo tipo de material	Pieza
7328	51300287	Agitador vortex de velocidad fija o variable	Pieza
7329	51300288	Nivel topografico	Pieza
7330	51300289	Sistema de entrenamiento en traductores, termistores y termopares	Pieza
7331	51300291	Concentrador de vacio	Pieza
7332	51300292	Camara de secuenciacion	Pieza
7333	51300293	Explosimetro/monitor/detector multigas	Pieza
7334	51300294	Güiro	Pieza
7335	51300295	Avion (Objeto liturgico para exposicion)	Pieza
7336	51300296	Helicoptero (Objeto liturgico para exposicion)	Pieza
7337	51300297	Embarcacion (Objeto liturgico para exposicion)	Pieza
7338	51300298	Equipo de comunicacion (objeto liturgico para exposicion)	Pieza
7339	51300299	Vehiculo anfibio (objeto liturgico para exposicion)	Pieza
7340	51300300	Aparatos e instrumentos, cientificos y de laboratorio (objeto liturgico para exposicion)	Pieza
7341	51300301	Vehiculos terrestres  (objeto liturgico para exposicion)	Pieza
7342	51300303	Armamento belico	Pieza
7343	5140	Objetos de valor	
7344	5150	Equipo de computo y de tecnologias de la informacion	
7345	51501	Bienes informaticos	
7346	51500001	Agenda electronica (palm) (eq. De computacion)	Pieza
7347	51500003	Camara de video para equipo multimedia (eq. De computacion)	Pieza
7348	51500004	Chasis para rack (eq. De computacion)	Pieza
7349	51500005	Cintoteca (eq. De computacion)	Pieza
7350	51500006	Computador main frame (eq. De computacion)	Pieza
7351	51500007	Concentradores (eq. De computacion)	Pieza
7352	51500008	Controladores (computacion) (eq. De computacion)	Pieza
7353	51500009	Convertidor analogico-digital (eq. De computacion)	Pieza
7354	51500010	Convertidor digital-analogico (eq. De computacion)	Pieza
7355	51500011	Cursor de 16 digitos (para tableta digitalizadora) (eq. De computacion)	Pieza
7356	51500012	Data show (eq. De computacion)	Pieza
7357	51500013	Descarbonizador (computacion) (eq. De computacion)	Pieza
7358	51500014	Digitalizador de imagen computarizada (scanner) (eq. De computacion)	Pieza
7359	51500015	Digitalizadores (tablero) (eq. De computacion)	Pieza
7360	51500016	Discoteca (eq. De computacion)	Pieza
7361	51500017	Dispositivo controlador de acceso a la red (relevador de señal) (eq. De computacion)	Pieza
7362	51500018	Duplicadora de diskettes (eq. De computacion)	Pieza
7363	51500019	Entrenador en electronica analogica  y digital (eq.p/conoc. Func. Circ. Dig.)	Pieza
7364	51500020	Entrenador en reproductor de compac disk (eq. p/conocer fallas en reproductores de cd)	Pieza
7365	51500021	Entrenador en videocasetera vhs (eq. p/conocer fallas en videocaset VHS)	Pieza
7366	51500022	Equipo asistente personal digital (microcomputadora de bolsillo o agenda personal) (eq. De computacion)	Pieza
7367	51500023	Equipo de proceso de palabras (eq. De computacion)	Pieza
7368	51500024	Equipo graficacion (eq. De computacion)	Pieza
7369	51500025	Equipo microfilmacion (eq. De computacion)	Pieza
7370	51500026	Equipo multifuncional (imprime, faxea, escanea y fotocopia) (eq. De computacion)	Pieza
7371	51500027	Equipo multimedia (cd-rom, tarjeta de sonido y bocinas) (eq. De computacion)	Pieza
7372	51500028	Equipo para credencializacion (impresora, camara, tripie, digitalizadores, kit de limpieza) (eq. De computacion)	Pieza
7373	51500029	Equipo para firma electronica (pad de firma) (eq. De computacion)	Pieza
7374	51500030	Esclavo inteligente (para sistema de grabado de llamadas telefonicas) (eq. De com., cinemat. O fotograf.)	Pieza
7375	51500031	Esclavo remoto (para sistema de grabado de llamadas telefonicas) (eq. De com., cinemat. O fotograf.)	Pieza
7376	51500032	Estacion de trabajo (eq. De computacion)	Pieza
7377	51500033	Grabadora cinta (eq. De computacion)	Pieza
7378	51500034	Grabadora disco (eq. de computacion)	Pieza
7379	51500035	Impresora (eq. De computacion)	Pieza
7380	51500036	Impresora de impacto de tambor, cadena o banda (eq. De computacion)	Pieza
7381	51500037	Impresora de matriz de impacto (eq. De computacion)	Pieza
7382	51500039	Impresora de monoelemento (eq. De computacion)	Pieza
7383	51500040	Impresora de transferencia termica (eq. de computacion)	Pieza
7384	51500041	Impresora inyeccion de tinta (eq. de computacion)	Pieza
7385	51500042	Impresora laser (eq. De computacion)	Pieza
7386	51500044	Interfases o acopladores (eq. De computacion)	Pieza
7387	51500045	Kit de expansion de almacenamiento (eq. De computacion)	Pieza
7388	51500046	Kit de herramientas para soporte tecnico a redes (eq. De computacion)	Pieza
7389	51500047	Lan extender (eq. De computacion)	Pieza
7390	51500048	Lapiz electronico  (eq. De computacion)	Pieza
7391	51500049	Lector de codigo de barras (terminal portatil)	Pieza
7392	51500050	Lector magnetico (eq. De computacion)	Pieza
7393	51500051	Lector microfichas (eq. De computacion)	Pieza
7394	51500052	Lector optico (eq. De computacion)	Pieza
7395	51500053	Lector tarjetas (eq. De computacion)	Pieza
7396	51500054	Lectora cintas papel (eq. De computacion)	Pieza
7397	51500055	Lectora y copiadora (eq. De computacion)	Pieza
7398	51500056	Maquina computadora-estadistica-mini-microprogramadora	Pieza
7399	51500057	Memoria magnetica (eq. De computacion)	Pieza
7400	51500058	Memoria nucleos (eq. De computacion)	Pieza
7401	51500059	Mesa piloteo (eq. De computacion)	Pieza
7402	51500060	Micro impresora  (eq. De computacion)	Pieza
7403	51500061	Micro-computadora (eq. De computacion)	Pieza
7404	51500062	Microcomputadora portatil (eq. De computacion)	Pieza
7405	51500063	Minicomputadora (eq. De computacion)	Pieza
7406	51500064	Modulo de conexion de fibra optica (eq. De computacion)	Pieza
7407	51500065	Monitor (eq. De computacion)	Pieza
7408	51500066	Multiplexor para video (eq. De computacion)	Pieza
7409	51500067	No-break (eq. De computacion)	Pieza
7410	51500068	Pedestal motorizado (para tableta digitalizadora) (eq. De computacion)	Pieza
7411	51500069	Perforador cintas de papel (eq. De computacion)	Pieza
7412	51500070	Perforador tarjetas (eq. De computacion)	Pieza
7413	51500071	Plotter (eq. De computacion)	Pieza
7414	51500072	Rack  (eq. De computacion)	Pieza
7415	51500073	Ruteador (eq. De computacion)	Pieza
7416	51500074	Scanner (eq. De computacion)	Pieza
7417	51500075	Separador formas continuas (eq. De computacion)	Pieza
7418	51500076	Servidor de multiusuario (eq. De computacion)	Pieza
7419	51500077	Servidor de red (eq. De computacion)	Pieza
7420	51500078	Servidor para sistema de grabacion digital (eq. De computacion)	Pieza
7421	56300093	Perforadora estaciones de perforacion de corazon de concreto	Pieza
7422	51500080	Sistema de grabado de numeros marcados dnr (telefonico) (eq. De com., cinemat. O fotograf.)	Pieza
7423	51500081	Sistema de grabado de numeros marcados dnr micro (telefonico) (eq. De com., cinemat. O fotograf.)	Pieza
7424	51500082	Sistemas controladores de teleproceso (eq. De computacion)	Pieza
7425	51500083	Switch para redes (equipo de conectividad) (eq. De computacion)	Pieza
7426	51500084	Tablero control luces aereas y velocidad (eq. De computacion)	Pieza
7427	51500085	Tableta digitalizadora (eq. De computacion)	Pieza
7428	51500086	Tarjeta ethernet etherlink (eq. De computacion)	Pieza
7429	51500087	Tarjeta system board o mother board (tarjeta madre) (eq. De computacion)	Pieza
7430	51500088	Tele impresor electronico (eq. De computacion)	Pieza
7431	51500089	Terminal teleproceso (programable y no programable) (eq. De computacion)	Pieza
7432	51500090	Transcriptora (eq. De computacion)	Pieza
7433	51500091	Unidad central de proceso (cpu) (eq. De computacion)	Pieza
7434	51500092	Unidad cinta magnetica (eq. De computacion)	Pieza
7435	56200389	Remalladora	Pieza
7436	51500093	Unidad de almacenamiento (eq. De computacion)	Pieza
7437	51500094	Unidad de cassette cinta magnetica (eq. De computacion)	Pieza
7438	51500095	Unidad disco magnetico fijo (eq. De computacion)	Pieza
7439	51500096	Unidad disco magnetico flexible (eq. De computacion)	Pieza
7440	51500097	Unidad disco magnetico removible (eq. De computacion)	Pieza
7441	51500098	Unidad duplicadora de discos compactos (eq. De computacion)	Pieza
7442	51500099	Unidad lectora de disco compacto externo (eq. De computacion)	Pieza
7443	51500100	Unidad multiple de discos opticos de/para lectura/escritura (jukebox) (eq. De computacion)	Pieza
7444	51500101	Unidad supervisora terminales (eq. De computacion)	Pieza
7445	51500102	Videoimpresora (eq. De computacion)	Pieza
7446	51500103	Video-proyector multimedia (cañon) (eq. De computacion)	Pieza
7447	51500104	Selector matricial de computo y audio y video (enrutador matricial)	Pieza
7448	51500105	Lectora de cheques	Pieza
7449	51500106	Dispositivo electronico portatil con pantalla tactil (Tablet)	Pieza
7450	51500107	Contenedor para centro de datos	Pieza
7451	51500108	Borrador de discos	Pieza
7452	51500109	Enfriador de discos (unidad de ventiladores)	Pieza
7453	51500110	Impresora 3D	Pieza
7454	51500111	Kiosco digital interactivo	Pieza
7455	5190	Otros mobiliarios y equipos de administracion	
7456	51901	Equipos de administracion	
7457	51900001	Abaco colocar bolas sorteo (eq. Deportivo o de campaña)	Pieza
7458	51900002	Acondicionador aire	Pieza
7459	51900003	Adresografo (maquina)	Pieza
7460	51900004	Afinadora placas impresion (eq. De reproduccion)	Pieza
7461	51900005	Alacena	Pieza
7462	51900006	Alargador de cangrejo para dibujo (eq. De pintura o dibujo)	Pieza
7463	51900007	Anda litera	Pieza
7464	51900008	Andadera	Pieza
7465	51900009	Aparato activador de etiquetas	Pieza
7466	51900010	Aparato contador de tarjetas	Pieza
7467	51900011	Aparato desactivador de etiquetas	Pieza
7468	51900012	Aparato etiquetador (eq. Para comercios)	Pieza
7469	51900013	Aparato lector de etiquetas	Pieza
7470	51900014	Aparato multiple moler verduras	Pieza
7471	51900015	Aparato para grabar informacion en etiquetas	Pieza
7472	51900016	Aparato para registro de acceso a traves de huella dactilar	Pieza
7473	51900017	Aparato reproductor formato karaoke (eq. de reproduccion)	Pieza
7474	51900018	Arco de seguridad y conteo de acceso	Pieza
7475	51900019	Armario	Pieza
7476	51900020	Aromatizador electrico	Pieza
7477	51900021	Aspiradora	Pieza
7478	51900023	Atril	Pieza
7479	51900024	Balanza de control digital electronica	Pieza
7480	51900025	Balanza electrica (explorer, de precision, etc.)	Pieza
7481	51900026	Balanza electro analitica	Pieza
7482	51900027	Bañera infantil	Pieza
7483	51900028	Bargueño (mueble)	Pieza
7484	51900029	Barra servicio (eq. Para comercios)	Pieza
7485	51900034	Bascula electronica	Pieza
7486	51900035	Bascula mecanica	Pieza
7487	51900036	Batidora (cocina)	Pieza
7488	51900037	Baul	Pieza
7489	51900038	Biombo y mampara	Pieza
7490	51900039	Botadero (eq. para comercios)	Pieza
7491	51900040	Boveda prefabricada para caudales	Pieza
7492	51900041	Buro	Pieza
7493	51900042	Buzon receptor y controlador de libros	Pieza
7494	51900043	Caballete (eq. de pintura o dibujo)	Pieza
7495	51900044	Cabecera	Pieza
7496	51900045	Cabecera gondola (eq. Para comercios)	Pieza
7497	51900046	Cafetera	Pieza
7498	51900047	Caja para almacen	Pieza
7499	51900048	Caja fuerte	Pieza
7500	51900049	Caja portatil seguridad	Pieza
7501	51900050	Caja separar dinero (eq. Para comercios)	Pieza
7502	51900051	Caja y tipos imprenta (juego) (eq. De reproduccion)	Pieza
7503	51900052	Calefactor (para oficina)	Pieza
7504	51900053	Calentador agua (para servicios de hoteleria hospitales, etc)	Pieza
7505	51900054	Cama madera o metal	Pieza
7506	51900055	Camara cuenta bolas sorteo (eq. Deportivo o de campaña)	Pieza
7507	51900056	Campana extraccion	Pieza
7508	51900057	Canastilla (productos) (eq. Para comercios)	Pieza
7509	51900058	Candil	Pieza
7510	51900059	Carriola	Pieza
7511	51900060	Carrito auto-servicio (eq. Para comercios)	Pieza
7512	51900061	Carro contabilidad	Pieza
7513	51900062	Carro percha (transporte ropa) (eq. Para comercios)	Pieza
7514	51900063	Carro porta manguera (aseo)	Pieza
7515	51900064	Carro porta-tambor espuma (aseo)	Pieza
7516	51900065	Carro recogedor loza y charolas	Pieza
7517	51900066	Carro tarjetero	Pieza
7518	51900067	Cerradora sobres	Pieza
7519	51900068	Cizalla o guillotina manual (para oficina)	Pieza
7520	51900069	Clasificadora de correspondencia	Pieza
7521	51900070	Colchon (box-spring)	Pieza
7522	51900071	Comoda	Pieza
7523	51900072	Compas (juego de) (eq. De pintura o dibujo)	Pieza
7524	51900073	Congelador	Pieza
7525	51900074	Congeladora (eq. Para comercios)	Pieza
7526	51900075	Consola	Pieza
7527	51900076	Consola conmutador	Pieza
7528	51900077	Contador para maquina franqueadora (metter)	Pieza
7529	51900078	Contrabarra servicio (eq. Para comercios)	Pieza
7530	51900079	Corral infantil	Pieza
7531	51900080	Cortador legumbres y verduras	Pieza
7532	51900081	Cortador placas lineas impresion (eq. De reproduccion)	Pieza
7533	51900082	Cuna	Pieza
7534	51900184	Maquina offset (eq. De reproduccion)	Pieza
7535	51900083	Desarmador electrico de  velocidad variable  con  bateria recargable (herramienta	Pieza
7536	51900084	Deshumificador	Pieza
7537	51900085	Detector de documentos falsos	Pieza
7538	51900086	Detector de explosivos	Pieza
7539	51900087	Diablo (carga)	Pieza
7540	51900088	Diccionario electronico	Pieza
7541	51900089	Embudo bola sorteo (eq. Deportivo o de campaña)	Pieza
7542	51900090	Empaquetadora de correspondencia	Pieza
7543	51900091	Enceradora	Pieza
7544	51900092	Encuadernadora (manual)	Pieza
7545	51900093	Enfriador y calentador agua	Pieza
7546	51900095	Engargoladora	Pieza
7547	51900096	Engargoladora perforadora	Pieza
7548	51900097	Engrapadoras para imprenta	Pieza
7549	51900098	Enmicadora	Pieza
7550	51900099	Equipo contra incendio	Pieza
7551	51900100	Equipo de alarma con circuito cerrado de television	Pieza
7552	51900101	Equipo de alarma detector de movimiento	Pieza
7553	51900102	Equipo de alarma detector magnetico	Pieza
7554	51900103	Equipo de video portero (telecamara y monitor con auricular) (eq. De reproduccion)	Pieza
7555	51900104	Equipo leteron (eq. De pintura o dibujo)	Pieza
7556	51900105	Equipo para autoprestamo	Pieza
7557	51900106	Escalera tipo tijera	Pieza
7558	51900107	Escalera tipo canastilla telescopica	Pieza
7559	51900108	Esfera sorteo (eq. Deportivo o de campaña)	Pieza
7560	51900109	Estante fruta (eq. Para comercios)	Pieza
7561	51900110	Estuche graphos (juego de) (eq. De pintura o dibujo)	Pieza
7562	51900111	Estuche leroy (juego de) (eq. De pintura o dibujo)	Pieza
7563	51900112	Estuche pedicure (juego de)	Pieza
7564	51900113	Estuche rapidografo (eq. De pintura o dibujo)	Pieza
7565	51900114	Estufa cocina (gas o electrica)	Pieza
7566	51900115	Estufon	Pieza
7567	51900116	Etiquetadora (eq. Para comercios)	Pieza
7568	51900117	Expendedora de timbres postales	Pieza
7569	51900118	Exprimidor frutas	Pieza
7570	51900120	Extractor aire	Pieza
7571	51900121	Extractor jugos	Pieza
7572	51900122	Fotocopiadora (eq. De reproduccion)	Pieza
7573	51900123	Fregadero	Pieza
7574	51900124	Freidor	Pieza
7575	51900125	Gabinete desperdicios	Pieza
7576	51900126	Gabinete fregadero	Pieza
7577	51900127	Gabinete iluminacion	Pieza
7578	51900128	Gabinete para extinguidor	Pieza
7579	51900129	Gabinete sanitario	Pieza
7580	51900130	Gondola (mercancias) (eq. Para comercios)	Pieza
7581	51900131	Grabadora de voz, camara digital y camara para pc (eq. de com., cinemat. o fotograf.)	Pieza
7582	51900132	Achurador (eq. de pintura o dibujo)	Pieza
7583	51900133	Horno cocina (gas o electrico)	Pieza
7584	51900134	Horno de microondas	Pieza
7585	51900135	Impresor calculadora	Pieza
7586	51900136	Impresora de codigo de barras (eq. De computacion)	Pieza
7587	51900137	Indexadora de correspondencia	Pieza
7588	51900138	Invernadero armable-desarmable	Pieza
7589	51900139	Juego comedor y desayunador	Pieza
7590	51900140	Juego muebles p/jardin  o parques (mesas, sillas, sombrilla)	Pieza
7591	51900141	Juego sala	Pieza
7592	51900142	Lampara con lupa	Pieza
7593	51900143	Lampara mesa	Pieza
7594	51900144	Lampara pie	Pieza
7595	51900145	Lampara restirador (eq. De pintura o dibujo)	Pieza
7596	51900146	Lampara techo	Pieza
7597	51900147	Lavadora alfombra	Pieza
7598	51900148	Lavadora pulidora pisos	Pieza
7599	51900149	Lavadora ropa	Pieza
7600	51900150	Lavadora trastos	Pieza
7601	51900151	Letrero electronico programable (eq. De com., cinemat. O fotograf.)	Pieza
7602	51900152	Licuadora (cocina)	Pieza
7603	51900153	Litera	Pieza
7604	51900154	Mamparas modulares para oficina	Pieza
7605	51900155	Maniquies (eq. Para comercios)	Pieza
7606	51900156	Maquina abrir correspondencia	Pieza
7607	51900157	Maquina calculadora electrica	Pieza
7608	51900158	Maquina cancelar documentos	Pieza
7609	51900159	Maquina contabilidad	Pieza
7610	51900160	Maquina contar billetes	Pieza
7611	51900161	Maquina contar monedas	Pieza
7612	51900162	Maquina cortadora planos	Pieza
7613	51900163	Maquina coser, electrica o mecanica	Pieza
7614	51900164	Maquina destructora documentos	Pieza
7615	51900165	Maquina dobladora insertadora y franqueadora	Pieza
7616	51900166	Maquina elaboracion estenciles electronicos (eq. De reproduccion)	Pieza
7617	51900167	Maquina enfriadora para bebidas	Pieza
7618	51900168	Maquina escribir electrica	Pieza
7619	51900169	Maquina escribir electrica compactas o semiportatiles	Pieza
7620	51900170	Maquina escribir electrica con cabezal esferico	Pieza
7621	51900171	Maquina escribir electrica de barra de tipos	Pieza
7622	51900172	Maquina escribir electrica no programable	Pieza
7623	51900173	Maquina escribir electronica	Pieza
7624	51900174	Maquina escribir electronica programable	Pieza
7625	51900175	Maquina escribir mecanica	Pieza
7626	51900176	Maquina escribir taquigrafia	Pieza
7627	51900177	Maquina esmaltadora (artes graficas) (eq. De reproduccion)	Pieza
7628	51900178	Maquina estereografica	Pieza
7629	51900179	Maquina franqueadora	Pieza
7630	51900180	Maquina generadora de vapor que asemeja humo o niebla	Pieza
7631	51900181	Maquina grabadora placas	Pieza
7632	51900182	Maquina heliografica (eq. De reproduccion)	Pieza
7633	51900183	Maquina linotipia (eq. De reproduccion)	Pieza
7634	51900185	Maquina procesadora microfilmadora (eq. De reproduccion)	Pieza
7635	51900186	Maquina protectora de cheques	Pieza
7636	51900187	Maquina registradora (eq. Para comercios)	Pieza
7637	51900188	Maquina reselladora	Pieza
7638	51900189	Maquina ribeteadora planos	Pieza
7639	51900190	Maquina sumadora manual o electrica	Pieza
7640	51900191	Marmita cocina	Pieza
7641	51900192	Matrizadora copiadora contacto (eq. De reproduccion)	Pieza
7642	51900193	Mecedora	Pieza
7643	51900194	Mesa con casilleros o pichoneras para separar cartas, boletos, apartado postal, etc.	Pieza
7644	51900195	Mesa corte de tela (eq. Para comercios)	Pieza
7645	51900196	Mesa jardin	Pieza
7646	51900197	Mesa para recibir vajilla	Pieza
7647	51900198	Mesa procesadora laminas tipograficas (eq. De reproduccion)	Pieza
7648	51900199	Microfilmadora (eq. De reproduccion)	Pieza
7649	51900200	Mimeografo (eq. De reproduccion)	Pieza
7650	51900201	Modular para equipo de computo (estacion para trabajo)	Pieza
7651	51900202	Modulo de correo rural (con buzon, casilleros de apartado postal y espacio para tel. Pub.	Pieza
7652	51900203	Molinete manual	Pieza
7653	51900204	Molino carne (cocina)	Pieza
7654	51900205	Mueble para cocina con gabinetes inferiores y 2 tarjas	Pieza
7655	51900206	Mueble para cocina tipo "l" con 1 tarja	Pieza
7656	51900207	Mueble para cocina tipo alacena dispensario	Pieza
7657	51900208	Mueble para cocina tipo cocineta con 1 tarja	Pieza
7658	51900209	Muebles bascula (eq. Para comercios)	Pieza
7659	51900210	Muebles promocional (exhibidor-mostrador) (eq. Para comercios)	Pieza
7660	51900211	Multigrafo (eq. De pintura o dibujo)	Pieza
7661	51900212	Pantografo (eq. De pintura o dibujo)	Pieza
7662	51900213	Pasillo revision (eq. Para comercios)	Pieza
7663	51900214	Pela papas (aparato)	Pieza
7664	51900215	Pizarron pie liso o ranurado	Pieza
7665	51900216	Pizarrones y rotafolios	Pieza
7666	51900217	Plancha	Pieza
7667	51900218	Planero	Pieza
7668	51900219	Plantimetro polar (eq. De pintura o dibujo)	Pieza
7669	51900221	Poste giratorio con base (eq. Para comercios)	Pieza
7670	51900222	Prensa papas	Pieza
7671	51900223	Punzon bolas-sorteo (eq. Deportivo o de campaña)	Pieza
7672	51900224	Purificador domestico agua	Pieza
7673	51900225	Racks (eq. Para comercios)	Pieza
7674	51900226	Rasuradora	Pieza
7675	51900227	Rebanadora electrica (cocina)	Pieza
7676	51900228	Redondeador esquinas	Pieza
7677	51900229	Refrigerador (cocina)	Pieza
7678	51900230	Refrigerador lacteos (eq. Para comercios)	Pieza
7679	51900231	Refrigerador salchichoneria (eq. Para comercios)	Pieza
7680	51900232	Registrador notas (eq. Para comercios)	Pieza
7681	51900233	Regla paralela  (eq. De pintura o dibujo)	Pieza
7682	51900234	Regla universal (eq. De pintura o dibujo)	Pieza
7683	51900235	Rejilla escurrimientos con repisa protectora (eq. Para comercios)	Pieza
7684	51900236	Reloj checador	Pieza
7685	51900237	Reloj cuerda pendulo	Pieza
7686	51900238	Reloj maestro	Pieza
7687	51900239	Reloj pared	Pieza
7688	51900240	Restirador	Pieza
7689	51900241	Rinconero	Pieza
7690	51900242	Rodillo pruebas tipografia (eq. De reproduccion)	Pieza
7691	51900243	Ropero	Pieza
7692	51900244	Rosticero	Pieza
7693	51900245	Sarten de volteo	Pieza
7694	51900246	Secador electrico manos	Pieza
7695	51900247	Secador estenciles (eq. De reproduccion)	Pieza
7696	51900248	Secadora planos (eq. De reproduccion)	Pieza
7697	51900249	Secadora ropa	Pieza
7698	51900250	Secreter	Pieza
7699	51900251	Segadora pasto electrica	Pieza
7700	51900252	Segadora pasto mecanica	Pieza
7701	51900253	Silla playa	Pieza
7702	51900254	Sombrilla jardin	Pieza
7703	51900255	Soporte universal para tv, videograbadora, etc. (pared o techo)	Pieza
7704	51900256	Tablero corcho y paño	Pieza
7705	51900257	Tablero ordenar bolas-sorteo (eq. Deportivo o de campaña)	Pieza
7706	51900258	Tanque gas (estacionario)	Pieza
7707	51900259	Television/pantalla plana  (eq. de com., cinemat. o fotograf.)	Pieza
7708	51900260	Tickometro (contador boletos)	Pieza
7709	51900261	Timer programable	Pieza
7710	51900262	Tiralineas (eq. De pintura o dibujo)	Pieza
7711	51900263	Tocador	Pieza
7712	51900264	Tostador pan	Pieza
7713	51900265	Trapecio esfera sorteo (eq. Deportivo o de campaña)	Pieza
7714	51900266	Trastero	Pieza
7715	51900267	Trinchador	Pieza
7716	51900268	Tripie para microfono	Pieza
7717	51900269	Triturador basura	Pieza
7718	51900270	Urna	Pieza
7719	51900271	Vaporizador para gas lp (suministrador constante de gas)	Pieza
7720	51900272	Ventilador	Pieza
7721	51900273	Video camara (eq. De reproduccion)	Pieza
7722	51900274	Vitrina	Pieza
7723	51900275	Dibujoscopio	Pieza
7724	51900276	Pulpo de serigrafia	Pieza
7725	51900277	Alarma de humo	Pieza
7726	51900279	Alarma sismica	Pieza
7727	51900280	Reloj Fechador	Pieza
7728	51900281	Podium	Pieza
7729	51900282	Procesador multifuncional de alimentos	Pieza
7730	51900283	Fabrica de helados	Pieza
7731	51900284	Crepera	Pieza
7732	51902	Adjudicaciones, expropiaciones e indemnizaciones de bienes muebles	
7733	5200	Mobiliario y equipo educacional y recreativo	
7734	5210	Equipos y aparatos audiovisuales	
7735	52101	Equipos y aparatos audiovisuales	
7736	52100001	Amplificador de señal de audio (eq. De com., cinemat. O fotograf.)	Pieza
7737	52100002	Amplificador proyector (eq. De com., cinemat. O fotograf.)	Pieza
7738	52100003	Carro microfono (eq. De com., cinemat. O fotograf.)	Pieza
7739	52100004	Carro porta proyector (eq. De com., cinemat. O fotograf.)	Pieza
7740	52100005	Carrusel transparencias (eq. De com., cinemat. O fotograf.)	Pieza
7741	52100006	Consola (eq. De com., cinemat. O fotograf.)	Pieza
7742	52100007	Grabadora (eq. De com., cinemat. O fotograf.)	Pieza
7743	52100008	Microfono (eq. De com., cinemat. O fotograf.)	Pieza
7744	52100009	Microfono ambiental de camara (eq. De com., cinemat. O fotograf.)	Pieza
7745	52100010	Micrograbadora (eq. De com., cinemat. O fotograf.)	Pieza
7746	52100011	Microproyector (eq. De com., cinemat. O fotograf.)	Pieza
7747	52100012	Monitor (eq. De com., cinemat. O fotograf.)	Pieza
7748	52100013	Montador transparencias (eq. De com., cinemat. O fotograf.)	Pieza
7749	52100014	Pantalla proyector (eq. De com., cinemat. O fotograf.)	Pieza
7750	52100015	Porta proyector cine (eq. De com., cinemat. O fotograf.)	Pieza
7751	52100016	Portalentes fotografia (eq. De com., cinemat. O fotograf.)	Pieza
7752	52100017	Proyector cinematografico de 16 mm. (eq. De com., cinemat. O fotograf.)	Pieza
7753	52100018	Proyector cinematografico de super 8 (eq. De com., cinemat. O fotograf.)	Pieza
7754	52100019	Proyector cuerpos opacos (eq. De com., cinemat. O fotograf.)	Pieza
7755	52100020	Proyector multiple (eq. De com., cinemat. O fotograf.)	Pieza
7756	52100021	Proyector transparencias (eq. De com., cinemat. O fotograf.)	Pieza
7757	52100022	Retroproyector (eq. De com., cinemat. O fotograf.)	Pieza
7758	52100023	Sincronizador sonido-transparencias (eq. De com., cinemat. O fotograf.)	Pieza
7759	52100024	Sintonizador (eq. De com., cinemat. O fotograf.)	Pieza
7760	52100025	Television con disco y/o cinta de video (eq. De com., cinemat. O fotograf.)	Pieza
7761	52100026	Tocacintas (eq. De com., cinemat. O fotograf.)	Pieza
7762	52100027	Tocadiscos (eq. De com., cinemat. O fotograf.)	Pieza
7763	52100028	Autoestereo	Pieza
7764	52100029	Lente u objetivo para todo tipo de camara	Pieza
7765	52100030	Quistitomos	Pieza
7766	5220	Aparatos deportivos	
7767	52201	Aparatos deportivos	
7768	52200001	Alfanje (eq. deportivo o de campaña)	Pieza
7769	52200002	Aparato ejercitador de abdomen y espalda (silla romana) (eq. Deportivo o de campaña)	Pieza
7770	52200003	Aparato simulador de remo (eq. Deportivo o de campaña)	Pieza
7771	52200004	Banco de pesas (eq. Deportivo o de campaña)	Pieza
7772	52200005	Barra olimpica (eq. Deportivo o de campaña)	Pieza
7773	52200006	Barras asimetricas (eq. Deportivo o de campaña)	Pieza
7774	52200007	Bicicleta electrica (eq. Deportivo o de campaña)	Pieza
7775	52200008	Binoculares (eq. Deportivo o de campaña)	Pieza
7776	52200009	Bodega inflable (eq. Deportivo o de campaña)	Pieza
7777	52200010	Caballo (con/sin arzones) (eq. Deportivo o de campaña)	Pieza
7778	52200011	Cama playa (eq. Deportivo o de campaña)	Pieza
7779	52200012	Caminadora electrica (eq. Deportivo o de campaña)	Pieza
7780	52200013	Carpa profesional de lona plastificada (incluye equipo completo) (eq. Deportivo o de campaña)	Pieza
7781	52200014	Carrusel caballitos (eq. Deportivo o de campaña)	Pieza
7782	52200015	Casa prefabricada (eq. Deportivo o de campaña)	Pieza
7783	52200016	Caseta desarmable (eq. Deportivo o de campaña)	Pieza
7784	52200017	Caseta pick up (eq. Deportivo o de campaña)	Pieza
7785	52200018	Cocineta movil (eq. Deportivo o de campaña)	Pieza
7786	52200019	Columpio (eq. Deportivo o de campaña)	Pieza
7787	52200020	Corneta (eq. Deportivo o de campaña)	Pieza
7788	52200021	Equipo oxigeno buceo (eq. Deportivo o de campaña)	Pieza
7789	52200022	Escaladora (aparato para musculacion piernas) (eq. Deportivo o de campaña)	Pieza
7790	52200023	Escalera arco (eq. Deportivo o de campaña)	Pieza
7791	52200024	Esfera metalica giratoria (eq. Deportivo o de campaña)	Pieza
7792	52200025	Espaldera de banco (eq. Deportivo o de campaña)	Pieza
7793	52200026	Estuche profesional ajedrez y backgammon (juego de) (eq. Deportivo o de campaña)	Pieza
7794	52200027	Florete (eq. Deportivo o de campaña)	Pieza
7795	52200028	Gimnasio universal (eq. Deportivo o de campaña)	Pieza
7796	52200029	Jungla aros (eq. Deportivo o de campaña)	Pieza
7797	52200030	Lampara submarina (eq. Deportivo o de campaña)	Pieza
7798	52200031	Mancuerna (pieza completa) (eq. Deportivo o de campaña)	Pieza
7799	52200032	Marcador juego de pelota que no es aro (eq. Deportivo o de campaña)	Pieza
7800	52200033	Mesa ajedrez (eq. Deportivo o de campaña)	Pieza
7801	52200034	Mesa billar (eq. Deportivo o de campaña)	Pieza
7802	52200035	Mesa ping pong (eq. Deportivo o de campaña)	Pieza
7803	52200036	Mesa separacion bolas-sorteo (eq. Deportivo o de campaña)	Pieza
7804	52200037	Ola infantil (eq. Deportivo o de campaña)	Pieza
7805	52200038	Paralelas (eq. Deportivo o de campaña)	Pieza
7806	52200039	Pasamanos (eq. Deportivo o de campaña)	Pieza
7807	52200040	Pesas (eq. Deportivo o de campaña)	Pieza
7808	52200041	Pistola salida atletismo (eq. Deportivo o de campaña)	Pieza
7809	52200042	Podium area de manos libres tipo reflex (eq. Deportivo o de campaña)	Pieza
7810	52200043	Porteria metalica para hand ball (eq. Deportivo o de campaña)	Pieza
7811	52200044	Reloj juego ajedrez (eq. Deportivo o de campaña)	Pieza
7812	52200045	Resbaladilla (eq. Deportivo o de campaña)	Pieza
7813	52200046	Ring oficial (box) (eq. Deportivo o de campaña)	Pieza
7814	52200047	Silla montar (eq. Deportivo o de campaña)	Pieza
7815	56200390	Rielera industrial	Pieza
7816	52200048	Sistema oleaje alberca (eq. Deportivo o de campaña)	Pieza
7817	52200049	Sube y baja (eq. Deportivo o de campaña)	Pieza
7818	52200050	Tabla abdominales (eq. Deportivo o de campaña)	Pieza
7819	52200051	Teatro portatil (eq. Deportivo o de campaña)	Pieza
7820	52200052	Tienda campaña (eq. Deportivo o de campaña)	Pieza
7821	52200053	Torre metalica basquet ball, portatil (eq. Deportivo o de campaña)	Pieza
7822	52200054	Trampolin (eq. Deportivo o de campaña)	Pieza
7823	52200055	Triciclo (eq. Deportivo o de campaña)	Pieza
7824	52200056	Twister disco para cintura (eq. Deportivo o de campaña)	Pieza
7825	52200057	Viga alta ajustable forrada (eq. Deportivo o de campaña)	Pieza
7826	52200058	Viga baja al piso (eq. Deportivo o de campaña)	Pieza
7827	52200059	Volantin (juego de) (eq. Deportivo o de campaña)	Pieza
7828	52200060	Lanzador de pelotas y/o balones	Pieza
7829	52200061	Artefacto sujeta balones	Pieza
7830	52200062	Soporte metalico para entrenamiento (costales de box, etc.)	Pieza
7831	52200063	Kit de indicadores para jugadores	Pieza
7832	52200064	Porta balones	Pieza
7833	52200065	Relojes de tiro	Pieza
7834	52200066	Pizarra electronica multideporte	Pieza
7835	5230	Camaras fotograficas y de video	
7836	52301	Camaras fotograficas y de video	
7837	52300001	Abrillantadora rotativa (eq. De com., cinemat. O fotograf.)	Pieza
7838	52300002	Adaptador filmina (eq. De com., cinemat. O fotograf.)	Pieza
7839	52300003	Adaptador rollo (eq. De com., cinemat. O fotograf.)	Pieza
7840	52300004	Alisador fotos (eq. De com., cinemat. O fotograf.)	Pieza
7841	52300005	Amplificador fotografico (eq. De com., cinemat. O fotograf.)	Pieza
7842	52300006	Amplificador pelicula (eq. De com., cinemat. O fotograf.)	Pieza
7843	52300007	Analizador color (fotografia) (eq. De com., cinemat. O fotograf.)	Pieza
7844	52300008	Aparato cortador pelicula (eq. De com., cinemat. O fotograf.)	Pieza
7845	52300009	Aparato cortar fotografias (eq. De com., cinemat. O fotograf.)	Pieza
7846	52300010	Aparato productor rotulos cine (eq. De com., cinemat. O fotograf.)	Pieza
7847	52300011	Aparato revelador copias fotostaticas y heliograficas (eq. De com., cinemat. O fotograf.)	Pieza
7848	52300012	Base camara microfichadora (eq. De com., cinemat. O fotograf.)	Pieza
7849	52300013	Bote y cilindro metal para revelado (eq. De com., cinemat. O fotograf.)	Pieza
7850	52300014	Caja carretes (cine) (eq. De com., cinemat. O fotograf.)	Pieza
7851	52300015	Calentador charola de revelado (eq. De com., cinemat. O fotograf.)	Pieza
7852	52300016	Camara cinematografica (eq. De com., cinemat. O fotograf.)	Pieza
7853	52300017	Camara de ionizacion y de burbujas (eq. De com., cinemat. O fotograf.)	Pieza
7854	52300018	Camara de video digital (eq. De reproduccion)	Pieza
7855	52300019	Camara eco (eq. De com., cinemat. O fotograf.)	Pieza
7856	52300020	Camara fotografica (eq. De com., cinemat. O fotograf.)	Pieza
7857	52300021	Camara fotografica digital (eq. De com., cinemat. O fotograf.)	Pieza
7858	52300022	Camara para videograbadora (eq. De com., cinemat. O fotograf.)	Pieza
7859	52300023	Cargador pelicula (eq. De com., cinemat. O fotograf.)	Pieza
7860	52300024	Chasis camara fotografica (eq. De com., cinemat. O fotograf.)	Pieza
7861	52300025	Control manual camara (eq. De com., cinemat. O fotograf.)	Pieza
7862	52300026	Copiador fotografias (eq. De com., cinemat. O fotograf.)	Pieza
7863	52300027	Copiadora electronica de cine (eq. De com., cinemat. O fotograf.)	Pieza
7864	52300028	Desempolvador peliculas (eq. De com., cinemat. O fotograf.)	Pieza
7865	52300029	Duplicador microfichas (eq. De com., cinemat. O fotograf.)	Pieza
7866	52300030	Editor y maquina edicion (cine) (eq. De com., cinemat. O fotograf.)	Pieza
7867	52300031	Editora de pelicula de microfichas (eq. De com., cinemat. O fotograf.)	Pieza
7868	52300032	Emparafinador pelicula (eq. De com., cinemat. O fotograf.)	Pieza
7869	52300033	Enrollador pelicula (eq. De com., cinemat. O fotograf.)	Pieza
7870	52300034	Equipo de filmacion (eq. De com., cinemat. O fotograf.)	Pieza
7871	52300035	Equipo fotocomposicion (eq. De com., cinemat. O fotograf.)	Pieza
7872	52300036	Equipo microfotografico (eq. De com., cinemat. O fotograf.)	Pieza
7873	52300037	Flash electronico (eq. De com., cinemat. O fotograf.)	Pieza
7874	52300038	Fuelle (eq. De com., cinemat. O fotograf.)	Pieza
7875	52300039	Fuente copiadora de cine (eq. De com., cinemat. O fotograf.)	Pieza
7876	52300040	Generador tiempo video grabadora (eq. De com., cinemat. O fotograf.)	Pieza
7877	52300041	Impresora fotografica (eq. De com., cinemat. O fotograf.)	Pieza
7878	52300042	Intercambiador automatico pelicula (eq. De com., cinemat. O fotograf.)	Pieza
7879	52300043	Lampara fotografica (eq. De com., cinemat. O fotograf.)	Pieza
7880	52300044	Lampara revelado (eq. De com., cinemat. O fotograf.)	Pieza
7881	52300045	Lampara seguridad cuarto obscuro (eq. De com., cinemat. O fotograf.)	Pieza
7882	52300046	Lavadora electrica copias fotograficas (eq. De com., cinemat. O fotograf.)	Pieza
7883	52300047	Maquina editora fotografia (eq. De com., cinemat. O fotograf.)	Pieza
7884	52300048	Maquina eliminacion impurezas fotograficas (eq. De com., cinemat. O fotograf.)	Pieza
7885	52300049	Marginador ampliar y reducir fotografias (eq. De com., cinemat. O fotograf.)	Pieza
7886	52300050	Motor arrastre camara cine (eq. De com., cinemat. O fotograf.)	Pieza
7887	52300051	Motor camara fotografica (eq. De com., cinemat. O fotograf.)	Pieza
7888	52300052	Moviola (eq. De com., cinemat. O fotograf.)	Pieza
7889	52300053	Nivel fotografias (eq. De com., cinemat. O fotograf.)	Pieza
7890	52300054	Plancha pegar fotos (eq. De com., cinemat. O fotograf.)	Pieza
7891	52300055	Porta-negativos (eq. De com., cinemat. O fotograf.)	Pieza
7892	52300056	Porta-peliculas (eq. De com., cinemat. O fotograf.)	Pieza
7893	52300057	Procesador color (fotografia) (eq. De com., cinemat. O fotograf.)	Pieza
7894	52300058	Procesadora amplificadora (eq. De com., cinemat. O fotograf.)	Pieza
7895	52300059	Programador filmina (eq. De com., cinemat. O fotograf.)	Pieza
7896	52300060	Punzon aerofotografico (eq. De com., cinemat. O fotograf.)	Pieza
7897	52300061	Regresador de video (eq. De reproduccion)	Pieza
7898	52300062	Reloj luminoso revelado (eq. De com., cinemat. O fotograf.)	Pieza
7899	52300063	Respaldo camara fotografias (eq. De com., cinemat. O fotograf.)	Pieza
7900	52300064	Rodillo secado fotografia (eq. De com., cinemat. O fotograf.)	Pieza
7901	52300065	Secador negativos (eq. De com., cinemat. O fotograf.)	Pieza
7902	52300066	Secadora fotos (eq. De com., cinemat. O fotograf.)	Pieza
7903	52300067	Selector secuencial video grabadora (eq. De com., cinemat. O fotograf.)	Pieza
7904	52300068	Sincronizador fotografia (eq. De com., cinemat. O fotograf.)	Pieza
7905	52300069	Tablero amplificacion fotografias (eq. De com., cinemat. O fotograf.)	Pieza
7906	52300070	Tablero grabacion (eq. De com., cinemat. O fotograf.)	Pieza
7907	52300071	Tablero monitor selector (eq. De com., cinemat. O fotograf.)	Pieza
7908	52300072	Tanque carrete revelado (eq. De com., cinemat. O fotograf.)	Pieza
7909	52300073	Teleconvertidor fotografico (eq. De com., cinemat. O fotograf.)	Pieza
7910	52300074	Telefoto (eq. De com., cinemat. O fotograf.)	Pieza
7911	52300075	Transportador automatico negativos (eq. De com., cinemat. O fotograf.)	Pieza
7912	52300076	Videocasetera (eq. De com., cinemat. O fotograf.)	Pieza
7913	52300077	Videograbadora (eq. De com., cinemat. O fotograf.)	Pieza
7914	52300078	Videoproyector (eq. De com., cinemat. O fotograf.)	Pieza
7915	52300079	Visor angulo camara cine (eq. De com., cinemat. O fotograf.)	Pieza
7916	52300080	Visor microfotografias (eq. De com., cinemat. O fotograf.)	Pieza
7917	52300081	Visor transparencias (eq. De com., cinemat. O fotograf.)	Pieza
7918	52300082	Dron	Pieza
7919	5290	Otro mobiliario y equipo educacional y recreativo	
7920	52901	Otro mobiliario y equipo educacional y recreativo	
7921	52900001	Alto parlante (eq. De com., cinemat. O fotograf.)	Pieza
7922	52900002	Bafle (eq. De com., cinemat. O fotograf.)	Pieza
7923	52900003	Barra para conversion a pizarron interactivo (eq. De com., cinemat. O fotograf.)	Pieza
7924	52900004	Bocina (eq. De com., cinemat. O fotograf.)	Pieza
7925	52900005	Caja acustica (eq. De com., cinemat. O fotograf.)	Pieza
7926	52900006	Caja guardar transparencias (eq. De com., cinemat. O fotograf.)	Pieza
7927	52900007	Caja traduccion (eq. De com., cinemat. O fotograf.)	Pieza
7928	52900008	Distorsionador instrumento musical (eq. De com., cinemat. O fotograf.)	Pieza
7929	52900009	Empalmador (eq. De com., cinemat. O fotograf.)	Pieza
7930	52900010	Equipo modular (eq. De com., cinemat. O fotograf.)	Pieza
7931	52900011	Indexadora microfichas (eq. De com., cinemat. O fotograf.)	Pieza
7932	52900012	Kit de iluminacion (eq. De com., cinemat. O fotograf.)	Pieza
7933	52900013	Laboratorio de idiomas (eq. De com., cinemat. O fotograf.)	Pieza
7934	52900014	Megafono (eq. De com., cinemat. O fotograf.)	Pieza
7935	52900015	Mesa fotografica (montaje) (eq. De com., cinemat. O fotograf.)	Pieza
7936	52900016	Mesa transparencias (eq. De com., cinemat. O fotograf.)	Pieza
7937	52900017	Opacimetro (eq. De com., cinemat. O fotograf.)	Pieza
7938	52900018	Pantalla tripie (eq. De com., cinemat. O fotograf.)	Pieza
7939	52900019	Prensa fotomontaje (eq. De com., cinemat. O fotograf.)	Pieza
7940	52900020	Reproductor de compact disc (eq. De com., cinemat. O fotograf.)	Pieza
7941	52900021	Tripie camara cine (eq. De com., cinemat. O fotograf.)	Pieza
7942	52900022	Tripie camara fotografica (eq. De com., cinemat. O fotograf.)	Pieza
7943	52900023	Unidad disolvencia (fotografia) (eq. De com., cinemat. O fotograf.)	Pieza
7944	52900024	Secadora de cabello (casco y pedestal)	Pieza
7945	52900025	Simulador de vuelo (eq. de com. cinemat. o fotograf.)	Pieza
7946	52900026	Bloques patron de calidad  (practicas estudiantiles)	Pieza
7947	52900027	Componentes didacticos para telecomunicaciones  (practicas estudiantiles)	Pieza
7948	52900028	Componentes y sistemas didacticos para reparacion de computadoras  (practicas estudiantiles)	Pieza
7949	52900029	Controlador multifunciones para diagnostico (practicas estudiantiles)	Pieza
7950	52900030	Entrenador en electronica  (practicas estudiantiles)	Pieza
7951	52900031	Entrenador en instalaciones (practicas estudiantiles)	Pieza
7952	52900032	Entrenador en pre y post calentamiento (practicas estudiantiles)	Pieza
7953	52900033	Entrenador para frenos  (practicas estudiantiles)	Pieza
7954	52900034	Entrenador para sistema de aire acondicionado (practicas estudiantiles)	Pieza
7955	52900035	Equipo didactico en hidraulica  (practicas estudiantiles)	Pieza
7956	52900036	Equipo didactico en neumatica  (practicas estudiantiles)	Pieza
7957	52900037	Escaner para diagnostico (practicas estudiantiles)	Pieza
7958	52900038	Extrusor  (practicas estudiantiles)	Pieza
7959	52900039	Maquina cortadora (practicas estudiantiles)	Pieza
7960	52900040	Maquina de coser (practicas estudiantiles)	Pieza
7961	52900041	Maquina de inyeccion (practicas estudiantiles)	Pieza
7962	52900042	Maquina extendedora (practicas estudiantiles)	Pieza
7963	52900043	Mesa digitalizadora (practicas estudiantiles)	Pieza
7964	52900044	Modular para reparacion de motores (practicas estudiantiles)	Pieza
7965	52900045	Modular para sistemas de inyeccion (practicas estudiantiles)	Pieza
7966	52900046	Modular para sistemas electronicos (practicas estudiantiles)	Pieza
7967	52900047	Molino pulverizador (practicas estudiantiles)	Pieza
7968	52900048	Programador universal (practicas estudiantiles)	Pieza
7969	56200391	Rodillo laminacion	Pieza
7970	52900049	Taladro (practicas estudiantiles)	Pieza
7971	52900050	Juego infantil para exteriores (casa de arbol, resbaladilla, puente, etc)	Pieza
7972	52900051	Modulo para preparar yogurt (practicas estudiantiles)	Pieza
7973	52900052	Simulador de entrenamiento para caninos	Pieza
7974	52900053	Juegos de mesa (ajedrez, domino, etc)	Pieza
7975	52900054	Porteria	Pieza
7976	52900055	Casa de campaña	Pieza
7977	52900056	Simulador femenino en etapa de gestacion (practicas academicas)	Pieza
7978	52900057	Simulador de examen de ojo (practicas academicas)	Pieza
7979	52900058	Simulador de examen de oido (practicas academicas)	Pieza
7980	52900059	Simulador para examen de prostata y recto (practicas academicas)	Pieza
7981	52900060	Simulador para examen de mama (practicas academicas)	Pieza
7982	52900061	Modelo anatomico para sonda urinaria (practicas academicas)	Pieza
7983	52900062	Mesa simuladora para casos clinicos (practicas academicas)	Pieza
7984	52900063	Modelo de conduccion de anestesia (practicas academicas)	Pieza
7985	52900064	Modelo de rayos X con tripie (practicas academicas)	Pieza
7986	52900065	Desfibrilador automatico para entrenamiento (practicas academicas)	Pieza
7987	52900066	Simulador para venoclisis	Pieza
7988	52900067	Entrenador modular para mecatronica	Pieza
7989	52900068	Entrenador en PLC y redes	Pieza
7990	52900069	Entrenador automatizado de control de procesos	Pieza
7991	52900070	Entrenador de prototipado PCB	Pieza
7992	52900071	Entrenador de consolidacion automatica de suelos	Pieza
7993	52900072	Entrenador compactadora de suelos	Pieza
7994	52900073	Entrenador de ensayo de corte	Pieza
7995	52900074	Entrenador para maniobra de Heimlich	Pieza
7996	52900075	Entrenador para RCP	Pieza
7997	52900076	Simulador de navegacion	Pieza
7998	52900077	Estacionamiento para bicicletas	Pieza
7999	5300	Equipo e instrumental medico y de laboratorio	
8000	5310	Equipo medico y de laboratorio	
8001	53101	Equipo medico y de laboratorio	
8002	53100001	Adaptador lateral tipo tapa para molino (instrumento cientifico)	Pieza
8003	53100002	Adelgazador mecanico (gatan dimple grinder) (instrumento cientifico)	Pieza
8004	53100003	Afilador cuchillo microtomo (equipo medico quirurgico)	Pieza
8005	53100004	Analizador de espectro, detector y filtro ms (instrumento cientifico)	Pieza
8006	53100005	Analizador de espectros por rayo laser (instrumento cientifico)	Pieza
8007	53100006	Andadera ortopedica (equipo medico quirurgico)	Pieza
8008	53100007	Aparato anestesia (equipo medico quirurgico)	Pieza
8009	53100008	Aparato articulador ortodontico (instrumental de laboratorio)	Pieza
8010	53100009	Aparato capilaridad (equipo medico quirurgico)	Pieza
8011	53100010	Aparato ciclomasaje (equipo medico quirurgico)	Pieza
8012	53100011	Aparato degasificador (equipo medico quirurgico)	Pieza
8013	53100012	Aparato diatermia (equipo medico quirurgico)	Pieza
8014	53100013	Aparato ejercitar tobillo (equipo medico quirurgico)	Pieza
8015	53100014	Aparato lavador tubos (equipo medico quirurgico)	Pieza
8016	53100015	Aparato ortopedico universal (equipo medico quirurgico)	Pieza
8017	53100016	Aparato para capilaridad (equipo medico quirurgico)	Pieza
8018	53100017	Aparato para medir tension de corrientes alternas (instrumento cientifico)	Pieza
8019	53100018	Aparato resucitador (equipo medico quirurgico)	Pieza
8020	53100019	Aparato traccion cervical (equipo medico quirurgico)	Pieza
8021	53100020	Aparato trepanacion (equipo medico quirurgico)	Pieza
8022	53100021	Aparatos para anestesia (equipo medico quirurgico)	Pieza
8023	53100022	Aparatos para diatermia (equipo medico quirurgico)	Pieza
8024	53100023	Armazon pruebas oftalmologicas (equipo medico quirurgico)	Pieza
8025	53100024	Artesa cunero (equipo medico quirurgico)	Pieza
8026	53100025	Aspirador multiple (equipo medico quirurgico)	Pieza
8027	53100026	Aspirador succion continua (equipo medico quirurgico)	Pieza
8028	53100027	Aspirador succion gastrica (equipo medico quirurgico)	Pieza
8029	53100028	Aspirador succion perilimbica (equipo medico quirurgico)	Pieza
8030	53100029	Aspirador succion rapida o toracica (equipo medico quirurgico)	Pieza
8031	53100030	Aspirador vaciamiento uterino (equipo medico quirurgico)	Pieza
8032	53100031	Aspirador vaciar bolsas (equipo medico quirurgico)	Pieza
8033	53100032	Aspiradores medico quirurgicos (instrumental de laboratorio)	Pieza
8034	53100033	Balanza granataria (electronica) (instrumento cientifico)	Pieza
8035	53100034	Banco anestesista (equipo medico quirurgico)	Pieza
8036	53100035	Banco laboratorio (equipo medico quirurgico)	Pieza
8037	53100036	Banco oftalmologia (equipo medico quirurgico)	Pieza
8038	53100037	Banqueta altura (equipo medico quirurgico)	Pieza
8039	53100038	Baño individual sauna (equipo medico quirurgico)	Pieza
8040	53100039	Baño lavador por ultrasonido (instrumento cientifico)	Pieza
8041	53100040	Baño maria (electrico) (equipo medico quirurgico)	Pieza
8042	53100041	Baño maria (utensilio) (equipo medico quirurgico)	Pieza
8043	53100042	Barras paralelas (medicina fisica) (equipo medico quirurgico)	Pieza
8044	53100045	Berbiqui ortopedia (equipo medico quirurgico)	Pieza
8045	53100046	Bicicleta fija rehabilitacion (equipo medico quirurgico)	Pieza
8046	53100047	Biombo proteccion rayos x (equipo medico quirurgico)	Pieza
8047	53100048	Blindaje para detector de centelleo (equipo medico quirurgico)	Pieza
8048	53100049	Bomba circulacion sanguinea (equipo medico quirurgico)	Pieza
8049	53100050	Bomba dosificadora (instrumento cientifico)	Pieza
8050	53100051	Bomba peristaltica (instrumento cientifico)	Pieza
8051	53100205	Lampara urologia (equipo medico quirurgico)	Pieza
8052	53100052	Bombas de muestreo personal (toma muestras de aire para analisis en ambiente laboral) (instrumento cientifico)	Pieza
8053	53100053	Bote acero inoxidable (equipo medico quirurgico)	Pieza
8054	53100054	Botiquin (equipo medico quirurgico)	Pieza
8055	53100055	Broncofibroscopio (equipo medico quirurgico)	Pieza
8056	53100056	Broncoscopio (equipo medico quirurgico)	Pieza
8057	53100057	Broncovideoscopio (equipo medico quirurgico)	Pieza
8058	53100058	Calentador biberones (equipo medico quirurgico)	Pieza
8059	53100059	Calentador porta objetos (equipo medico quirurgico)	Pieza
8060	53100060	Calentador recirculador de inmersion (instrumento cientifico)	Pieza
8061	53100061	Calibrador  multifunciones (para sensores de temperatura) (instrumento cientifico)	Pieza
8062	53100062	Calibrador fuentes de poder (para corriente alterna) (instrumento cientifico)	Pieza
8063	53100063	Calibrador oscilador (para frecuencimetros, contadores universales, generador de señales) (instrumento cientifico)	Pieza
8064	53100064	Calibrador para linea de aire del analizador de redes (instrumento cientifico)	Pieza
8065	53100065	Cama circulo (equipo medico quirurgico)	Pieza
8066	53100066	Cama clinica (equipo medico quirurgico)	Pieza
8067	53100067	Cama pediatrica (equipo medico quirurgico)	Pieza
8068	53100068	Camara de temperatura y humedad para calibrar higrometros (instrumento cientifico)	Pieza
8069	53100069	Camara radiacion (equipo medico quirurgico)	Pieza
8070	53100070	Campana de bioseguridad (instrumental de laboratorio)	Pieza
8071	53100071	Canastilla termometros (equipo medico quirurgico)	Pieza
8072	53100072	Cardioscopio (equipo medico quirurgico)	Pieza
8073	53100073	Cardio-sincronizador (equipo medico quirurgico)	Pieza
8074	53100074	Carpeta de tablas de colores (compara colores d/suelos, sedimentos, ceramicas, plantas, anim., etc.)  (instrumental de laboratorio)	Pieza
8075	53100075	Carro camilla (equipo medico quirurgico)	Pieza
8076	53100076	Carro cuna termico con resucitador (equipo medico quirurgico)	Pieza
8077	53100077	Carro curaciones (equipo medico quirurgico)	Pieza
8078	53100078	Carro dializador (equipo medico quirurgico)	Pieza
8079	53100079	Carro laboratorio (equipo medico quirurgico)	Pieza
8080	53100080	Carro microscopio (equipo medico quirurgico)	Pieza
8081	53100081	Carro monitor (equipo medico quirurgico)	Pieza
8082	53100082	Carro para material esteril (equipo medico quirurgico)	Pieza
8083	53100083	Carro para medicamentos (equipo medico quirurgico)	Pieza
8084	53100084	Carro porta-bandejas (equipo medico quirurgico)	Pieza
8085	53100085	Carro porta-historias clinicas (equipo medico quirurgico)	Pieza
8086	53100086	Carro tanico (porta bolsas) (equipo medico quirurgico)	Pieza
8087	53100087	Carro transportar alimentos (equipo medico quirurgico)	Pieza
8088	53100088	Carro transportar autoclaves (equipo medico quirurgico)	Pieza
8089	53100089	Carro transportar material radiactivo (equipo medico quirurgico)	Pieza
8090	53100090	Catetometro (equipo medico quirurgico)	Pieza
8091	53100091	Sensor inalambrico de temperatura (instrumento cientifico)	Pieza
8092	53100092	Chaleco seguridad medico quirurgico (equipo medico quirurgico)	Pieza
8093	53100093	Chasis rayos x (equipo medico quirurgico)	Pieza
8094	53100094	Cistoscopio (equipo medico quirurgico)	Pieza
8095	53100095	Cizalla medica (equipo medico quirurgico)	Pieza
8096	53100096	Cofre rayos x (equipo medico quirurgico)	Pieza
8097	53100097	Collar dolicocefalo (equipo medico quirurgico)	Pieza
8098	53100098	Collimator para rayos x  (instrumento cientifico)	Pieza
8099	53100099	Colonsigmoidoscopio (equipo medico quirurgico)	Pieza
8100	53100100	Columpio ortopedia (equipo medico quirurgico)	Pieza
8101	53100101	Compactador neumatico	Pieza
8102	53100102	Comparador optico (medidor y calibrador) (instrumento cientifico)	Pieza
8103	53100103	Compresor succionador (equipo medico quirurgico)	Pieza
8104	53100104	Consola dialisis (equipo medico quirurgico)	Pieza
8105	53100105	Consola resucitador cardiaco (equipo medico quirurgico)	Pieza
8106	53100106	Control indicador de vacio (instrumento cientifico)	Pieza
8107	53100107	Controlador distribuidor digital de rotacion y velocidad para motor de transmision (instrumento cientifico)	Pieza
8108	53100108	Controlador tipo din de temperatura (instrumento cientifico)	Pieza
8109	53100109	Cortadora electrica gasa (equipo medico quirurgico)	Pieza
8110	53100110	Culdoscopio (equipo medico quirurgico)	Pieza
8111	53100111	Derivador de intensidad de corriente continua  (instrumento cientifico)	Pieza
8112	53100112	Dermatomo electrico (equipo medico quirurgico)	Pieza
8113	53100113	Desarmador automatico, puntas cambiables (equipo medico quirurgico)	Pieza
8114	53100114	Desarmador ortopedico (equipo medico quirurgico)	Pieza
8115	53100115	Desfibrilador para cardiologia (equipo medico quirurgico)	Pieza
8116	53100116	Diploscopio (equipo medico quirurgico)	Pieza
8117	53100117	Disipador de calor para relay (instrumento cientifico)	Pieza
8118	53100118	Disociador (equipo medico quirurgico)	Pieza
8119	53100119	Dispositivo cortar cerebro (equipo medico quirurgico)	Pieza
8120	53100120	Electrobisturi (equipo medico quirurgico)	Pieza
8121	53100121	Electrocardioscopio (equipo medico quirurgico)	Pieza
8122	53100122	Electroscopio (equipo medico quirurgico)	Pieza
8123	53100123	Electrotomo prostatico (equipo medico quirurgico)	Pieza
8124	53100124	Enfriador muestras laboratorio (equipo medico quirurgico)	Pieza
8125	53100125	Enfriador recirculador para absorcion atomica (instrumento cientifico)	Pieza
8126	53100126	Entalcador guantes (equipo medico quirurgico)	Pieza
8127	53100127	Epidiascopio (equipo medico quirurgico)	Pieza
8128	53100128	Equipo alimentacion parenteral (equipo medico quirurgico)	Pieza
8129	53100129	Equipo de analisis para identificar tipo de atomo en la muestra (instrumental de laboratorio)	Pieza
8130	53100130	Equipo de barrido para el detector de fallas (instrumento cientifico)	Pieza
8131	53100131	Equipo de campo para transcopiado (instrumento cientifico)	Pieza
8132	53100132	Equipo de corrientes electromagneticas (instrumento cientifico)	Pieza
8133	53100133	Equipo de corrosion (potenciostato/galvanostato) (instrumento cientifico)	Pieza
8134	53100134	Equipo de inmuno ensayo enzimatico (equipo medico quirurgico)	Pieza
8135	53100135	Equipo de pulido y ataque electrolitico  (instrumento cientifico)	Pieza
8136	53100136	Equipo de rayos x (equipo medico quirurgico)	Pieza
8137	53100137	Equipo electro encefalografo (equipo medico quirurgico)	Pieza
8138	53100138	Equipo electrocardiografo (equipo medico quirurgico)	Pieza
8139	53100139	Equipo medidor de oxigeno, solidos disueltos y temperatura  (instrumento cientifico)	Pieza
8140	53100140	Equipo microdiseccion (equipo medico quirurgico)	Pieza
8141	53100141	Equipo ortopedico cadera (equipo medico quirurgico)	Pieza
8142	53100142	Equipo oxigeno terapia (equipo medico quirurgico)	Pieza
8143	53100143	Equipo para analisis termogravimetrico y deferencial termico (instrumento cientifico)	Pieza
8144	53100144	Equipo para prueba de dureza de materiales (microhardness) (instrumento cientifico)	Pieza
8145	53100145	Equipo para pruebas de abrasion o desgaste (instrumento cientifico)	Pieza
8146	53100146	Equipo para recorte, pulido, terminado, etc. De aparatos protesicos (instrumental de laboratorio)	Pieza
8147	53100147	Equipo tomografia (equipo medico quirurgico)	Pieza
8148	53100148	Espirometro (aparato) (equipo medico quirurgico)	Pieza
8149	53100150	Estativo fotografico (instrumental de laboratorio)	Pieza
8150	53100151	Estereoscopio (equipo medico quirurgico)	Pieza
8151	53100152	Esterilizadores (equipo medico quirurgico)	Pieza
8152	53100153	Esterilizadores medico  quirurgicos (instrumental de laboratorio)	Pieza
8153	53100154	Estetoscopio biauricular (equipo medico quirurgico)	Pieza
8154	53100155	Estetoscopio corazon fetal (equipo medico quirurgico)	Pieza
8155	53100156	Estetoscopio electronico (equipo medico quirurgico)	Pieza
8156	53100157	Estetoscopio esofagico (equipo medico quirurgico)	Pieza
8157	53100158	Estetoscopio obstetrico (equipo medico quirurgico)	Pieza
8158	53100159	Estetoscopio ultrasonico (equipo medico quirurgico)	Pieza
8159	53100160	Estimulador nervios (equipo medico quirurgico)	Pieza
8160	53100161	Estuche cirugia (jgo. De) (equipo medico quirurgico)	Pieza
8161	53100162	Estuche diagnostico (jgo. De) (equipo medico quirurgico)	Pieza
8162	53100163	Estuche diseccion (jgo. De) (equipo medico quirurgico)	Pieza
8163	53100164	Estuche lentes pruebas oftalmologicas (jgo. De) (equipo medico quirurgico)	Pieza
8164	53100165	Estuche parodoncia (jgo. De) (equipo medico quirurgico)	Pieza
8165	53100166	Estuche proctologia (jgo. De) (equipo medico quirurgico)	Pieza
8166	53100167	Estuche sutura (jgo. De) (equipo medico quirurgico)	Pieza
8167	53100168	Estufa laboratorio (equipo medico quirurgico)	Pieza
8168	53100169	Fibroscopio (equipo medico quirurgico)	Pieza
8169	53100170	Filtro de agua (filtra agua reteniendo sales en cartuchos) (instrumento cientifico)	Pieza
8170	53100171	Filtro de arena con bomba integrada para acuarios de acuacultura (aparato cientifico)	Pieza
8171	53100172	Filtro de tierras diatomeas con valvula multipuerto para acuarios de acuacultura (aparato cientifico)	Pieza
8172	53100173	Filtro staplex (equipo medico quirurgico)	Pieza
8173	53100174	Fuente luz fria (equipo medico quirurgico)	Pieza
8174	53100175	Fuente poder (equipo medico quirurgico)	Pieza
8175	53100176	Gabinete curaciones (equipo medico quirurgico)	Pieza
8176	53100177	Gabinete instrumental quirurgico (equipo medico quirurgico)	Pieza
8177	53100178	Gabinete porta historia clinica (equipo medico quirurgico)	Pieza
8178	53100179	Gastroscopio (equipo medico quirurgico)	Pieza
8179	53100180	Generador de funciones arbitrarias (instrumento cientifico)	Pieza
8180	53100181	Glucometro (equipo medico quirurgico)	Pieza
8181	53100182	Hematimetro (equipo medico quirurgico)	Pieza
8182	53100183	Hemoglobinometro (equipo medico quirurgico)	Pieza
8183	53100184	Hielera vacunas (equipo medico quirurgico)	Pieza
8184	53100185	Horno secado y esterilizacion (equipo medico quirurgico)	Pieza
8185	53100186	Incubadora	Pieza
8186	53100187	Inspeccion fluoroscopio rayos x (maquina) (equipo medico quirurgico)	Pieza
8187	53100188	Integrador (instrumental de laboratorio)	Pieza
8188	53100189	Interfase adaptador para conectar medidor de fuentes de poder (instrumento cientifico)	Pieza
8189	53100190	Ionizador ambiental (equipo medico quirurgico)	Pieza
8190	53100191	Jabonera cirujano (equipo medico quirurgico)	Pieza
8191	53100192	Jeringa dental de aspiracion y auto aspiracion (tipo carpule) (equipo medico quirurgico)	Pieza
8192	53100193	Juego de barras y sujetadores para baños liquidos (instrumento cientifico)	Pieza
8193	53100194	Juego de blocks patron para comparador optico (instrumento cientifico)	Pieza
8194	53100195	Lampara cirugia (equipo medico quirurgico)	Pieza
8195	53100196	Lampara cirugia oftalmologica (equipo medico quirurgico)	Pieza
8196	53100197	Lampara de fotopolimerizacion de resinas para uso dental (instrumental de laboratorio)	Pieza
8197	53100198	Lampara de luz ultravioleta (instrumento cientifico)	Pieza
8198	53100199	Lampara emergencia quirofano (equipo medico quirurgico)	Pieza
8199	53100200	Lampara frontal (equipo medico quirurgico)	Pieza
8200	53100201	Lampara observacion aglutinacion eritrocitos (equipo medico quirurgico)	Pieza
8201	53100202	Lampara otorrino (equipo medico quirurgico)	Pieza
8202	53100203	Lampara radiacion infrarroja o ultravioleta (equipo medico quirurgico)	Pieza
8203	53100204	Lampara reflejos (equipo medico quirurgico)	Pieza
8204	53100206	Laringoscopio (equipo medico quirurgico)	Pieza
8205	53100207	Lava comodos (equipo medico quirurgico)	Pieza
8206	53100208	Lavabo cirujano (equipo medico quirurgico)	Pieza
8207	53100209	Lavador de gases (instrumento cientifico)	Pieza
8208	53100210	Lavadora agujas (equipo medico quirurgico)	Pieza
8209	53100211	Lavadora biberones (equipo medico quirurgico)	Pieza
8210	53100212	Lavadora guantes (equipo medico quirurgico)	Pieza
8211	53100213	Lavadora instrumental y jeringas (equipo medico quirurgico)	Pieza
8212	53100214	Lavadora secadora pipetas (equipo medico quirurgico)	Pieza
8213	53100215	Lector de microplacas (instrumento cientifico)	Pieza
8214	53100216	Llenador biberones (equipo medico quirurgico)	Pieza
8215	53100217	Magnetizador detector de fisuras en materiales ferrosos (instrumento cientifico)	Pieza
8216	53100218	Manifold para vacio  (instrumento cientifico)	Pieza
8217	53100219	Maquina casquillos dentales (equipo medico quirurgico)	Pieza
8218	53100220	Maquina para confeccion de guarda oclusal (placa terapeutica dental) (instrumental de laboratorio)	Pieza
8219	53100221	Maquina perfora-tapones (equipo medico quirurgico)	Pieza
8220	53100222	Marco (pesas-patron) (equipo medico quirurgico)	Pieza
8221	53100223	Marco radiografia (equipo medico quirurgico)	Pieza
8222	53100224	Marro ortopedico (equipo medico quirurgico)	Pieza
8223	53100225	Mastil telescopico (soporte de diversos monitores de parametros metereologicos) (instrumento cientifico)	Pieza
8224	53100226	Medidor  tds (de concentracion de solidos disueltos en agua) (instrumento cientifico)	Pieza
8225	53100227	Medidor de intensidad de luz uv (instrumento cientifico)	Pieza
8226	53100228	Medidor de parametros multiples de laboratorio (instrumento cientifico)	Pieza
8227	53100229	Medidor del ph por conductividad electrica (instrumento cientifico)	Pieza
8228	53100230	Mesa autopsia (equipo medico quirurgico)	Pieza
8229	53100231	Mesa campimetria (equipo medico quirurgico)	Pieza
8230	53100232	Mesa carro anestesiologo (equipo medico quirurgico)	Pieza
8231	53100233	Mesa curaciones (equipo medico quirurgico)	Pieza
8232	53100234	Mesa de cirugia (equipo medico quirurgico)	Pieza
8233	53100235	Mesa exploracion (equipo medico quirurgico)	Pieza
8234	53100236	Mesa hidraulica cirugia (equipo medico quirurgico)	Pieza
8235	53100237	Mesa hidraulica proctologia (equipo medico quirurgico)	Pieza
8236	53100238	Mesa instrumental cirugia (equipo medico quirurgico)	Pieza
8237	53100239	Mesa metabolismo basal (equipo medico quirurgico)	Pieza
8238	53100240	Mesa oftalmologia (equipo medico quirurgico)	Pieza
8239	53100241	Mesa para carga y descarga de peliculas radiologicas (equipo medico quirurgico)	Pieza
8240	53100242	Mesa para distribucion de placas radiograficas (equipo medico quirurgico)	Pieza
8241	53100243	Mesa para ensamble con repisa intermedia (equipo medico quirurgico)	Pieza
8242	53100244	Mesa para interpretacion de placas radiograficas (equipo medico quirurgico)	Pieza
8243	53100245	Mesa pediatrica (equipo medico quirurgico)	Pieza
8244	53100246	Mesa prenatal (equipo medico quirurgico)	Pieza
8245	53100247	Mesa rayos x (equipo medico quirurgico)	Pieza
8246	53100248	Mesa rehabilitacion (equipo medico quirurgico)	Pieza
8247	53100249	Mesa urologica (equipo medico quirurgico)	Pieza
8248	53100250	Microscopio de comparacion para balistica con camara fotografica (instrumento cientifico)	Pieza
8249	53100251	Molino para muestras ceramicas (instrumento cientifico)	Pieza
8250	53100252	Monitor de pelicula fina (controla el espesor del recubrimiento de muestra) (instrumento cientifico)	Pieza
8251	53100253	Mortero automatico (equipo medico quirurgico)	Pieza
8252	53100254	Motor de transmision rotativa para bomba peristaltica (instrumento cientifico)	Pieza
8253	53100255	Nasofaringoscopio (equipo medico quirurgico)	Pieza
8254	53100256	Nebulizadores (equipo medico quirurgico)	Pieza
8255	53100257	Negatoscopio (equipo medico quirurgico)	Pieza
8256	53100258	Niveles electronicos para calibrar mesas de planitud (instrumento cientifico)	Pieza
8257	53100259	Oftalmometro (equipo medico quirurgico)	Pieza
8258	53100260	Orinal (equipo medico quirurgico)	Pieza
8259	53100261	Osciloscopio (uso medico) (equipo medico quirurgico)	Pieza
8260	53100262	Osteotomo (equipo medico quirurgico)	Pieza
8261	53100263	Pantalla optotipos (equipo medico quirurgico)	Pieza
8262	53100264	Pelvimetro (equipo medico quirurgico)	Pieza
8263	53100265	Pendulo para pruebas de impacto (mide resistencia al impacto de diferentes materiales) (instrumento cientifico)	Pieza
8264	53100266	Percolador o lixiviador (equipo medico quirurgico)	Pieza
8265	53100267	Perforador universal hueso (equipo medico quirurgico)	Pieza
8266	53100268	Perno montaje (experimentos opticos) (equipo medico quirurgico)	Pieza
8267	53100269	Picnometro tipo gay-lussac (instrumento cientifico)	Pieza
8268	53100270	Pipeteador automatico (equipo medico quirurgico)	Pieza
8269	53100271	Porta agujas quirurgico (equipo medico quirurgico)	Pieza
8270	53100272	Porta chasis (equipo medico quirurgico)	Pieza
8271	53100273	Porta cubeta patada (equipo medico quirurgico)	Pieza
8272	53100274	Porta gasa (equipo medico quirurgico)	Pieza
8273	53100275	Porta pernos (experimentos opticos) (equipo medico quirurgico)	Pieza
8274	53100276	Porta pipetas (equipo medico quirurgico)	Pieza
8275	53100277	Porta suero (equipo medico quirurgico)	Pieza
8276	53100278	Procesador de datos micropak (instrumento cientifico)	Pieza
8277	53100279	Proctosigmoidoscopio (equipo medico quirurgico)	Pieza
8278	53100280	Proyectores oftalmicos (equipo medico quirurgico)	Pieza
8279	53100281	Rack esterilizacion clavos-tornillos (equipo medico quirurgico)	Pieza
8280	53100282	Recirculador de agua (instrumento cientifico)	Pieza
8281	54100045	Track mobile	Pieza
8282	53100283	Rectosigmoidoscopio (equipo medico quirurgico)	Pieza
8283	53100284	Recubridor de muestras (sputtering) (instrumento cientifico)	Pieza
8284	53100285	Refrigerador banco-sangre (equipo medico quirurgico)	Pieza
8285	53100286	Refrigerador cadaveres (equipo medico quirurgico)	Pieza
8286	53100287	Refrigerador laboratorio (equipo medico quirurgico)	Pieza
8287	53100288	Rejilla colectora de polvo para molino simoloyer (varias medidas) (instrumento cientifico)	Pieza
8288	53100289	Rejilla contenedor de muestras para molino simoloyer (instrumento cientifico)	Pieza
8289	53100290	Resectoscopio (equipo medico quirurgico)	Pieza
8290	53100291	Rinofaringoscopio (equipo medico quirurgico)	Pieza
8291	53100292	Riñon artificial (equipo medico quirurgico)	Pieza
8292	53100293	Secador placas radiograficas (equipo medico quirurgico)	Pieza
8293	53100294	Sellador de placas quanti tray (instrumento cientifico)	Pieza
8294	53100295	Sierra cortar yeso (equipo medico quirurgico)	Pieza
8295	53100296	Sierra electrica necropsia (equipo medico quirurgico)	Pieza
8296	53100297	Sierra hueso (manual y electrica) (equipo medico quirurgico)	Pieza
8297	53100298	Sierra oscilatoria (equipo medico quirurgico)	Pieza
8298	53100299	Sigmoidoscopio (equipo medico quirurgico)	Pieza
8299	53100300	Silla ruedas (equipo medico quirurgico)	Pieza
8300	53100301	Sillon alberca terapeutica (equipo medico quirurgico)	Pieza
8301	53100302	Sillon hidraulico dental (equipo medico quirurgico)	Pieza
8302	53100303	Sillon hidraulico oftalmologia (equipo medico quirurgico)	Pieza
8303	53100304	Sistema cuidado intensivo (equipo medico quirurgico)	Pieza
8304	53100305	Sistema de calibracion de temperatura, calibrador de bloques metalicos (instrumento cientifico)	Pieza
8305	53100306	Sistema de genetica forense para la identificacion humana (instrumento cientifico)	Pieza
8306	53100307	Sistema de microanalisis (espectrometro de energia dispersa) (instrumento cientifico)	Pieza
8307	53100308	Sistema de pulido ionico de precision  (instrumento cientifico)	Pieza
8308	53100309	Sistema irrigacion calorica (equipo medico quirurgico)	Pieza
8309	53100310	Sistema para la identificacion de analisis balistica (instrumental de laboratorio)	Pieza
8310	53100311	Switch relay temperatura (instrumento cientifico)	Pieza
8311	53100312	Tablero para terapia ocupacional (equipo medico quirurgico)	Pieza
8312	53100313	Taladro ortopedico (equipo medico quirurgico)	Pieza
8313	53100314	Tanque almacenamiento liquidos (medico quirurgico) (equipo medico quirurgico)	Pieza
8314	53100315	Tanque baño parafina (equipo medico quirurgico)	Pieza
8315	53100316	Tanque remolino (equipo medico quirurgico)	Pieza
8316	53100317	Tanque revelador radiografia (equipo medico quirurgico)	Pieza
8317	53100318	Termociclador (instrumental de laboratorio)	Pieza
8318	53100319	Termocople mtch medidor de temperatura -htdta (instrumento cientifico)	Pieza
8319	53100320	Timon ejercicios (equipo medico quirurgico)	Pieza
8320	53100321	Tina evaporacion (equipo medico quirurgico)	Pieza
8321	53100322	Trefina trasplante craneal (equipo medico quirurgico)	Pieza
8322	53100323	Tripie porta suero (equipo medico quirurgico)	Pieza
8323	53100324	Unidad axioencefalografia (equipo medico quirurgico)	Pieza
8324	53100325	Unidad criocirugia (equipo medico quirurgico)	Pieza
8325	53100326	Unidad de iluminacion para comparador optico (instrumento cientifico)	Pieza
8326	53100327	Unidad dental (equipo medico quirurgico)	Pieza
8327	53100328	Unidad electro quirurgica (equipo medico quirurgico)	Pieza
8328	53100329	Unidad otorrino (equipo medico quirurgico)	Pieza
8329	53100330	Unidad portatil rayos x (equipo medico quirurgico)	Pieza
8330	53100331	Uretroscopio (equipo medico quirurgico)	Pieza
8331	53100332	Valvula hidraulica obstruccion de flujo de vacio (instrumento cientifico)	Pieza
8332	53100333	Valvula indicadora de vacio tipo magnetron (instrumento cientifico)	Pieza
8333	53100334	Valvula interruptor electromecanico de vacio (instrumento cientifico)	Pieza
8334	53100335	Ventilador terapia respiratoria (equipo medico quirurgico)	Pieza
8335	53100336	Baropodometro	Pieza
8336	53100337	Torso para practicas de resucitacion cardiopulmonar	Pieza
8337	53100338	Soporte metalico con tenazas	Pieza
8338	53100341	Base soporte de matraces	Pieza
8339	53100342	Copeladora o moldeadora de metal	Pieza
8340	53100344	Mantilla de calentamiento con agitador	Pieza
8341	53100345	Maquina para preparacion de probetas	Pieza
8342	53100346	Lavaojos para pared, pedestal o portatil con/sin tina	Pieza
8343	53100347	Aparatos de rehabilitacion	Pieza
8344	53100348	Equipo de prueba de susceptibilidad (instrumental medico y de laboratorio)	Pieza
8345	53100349	Equipo de exploracion (equipo medico quirurgico)	Pieza
8346	53100350	Equipo de prueba de sensibilidad (instrumental medico y de laboratorio)	Pieza
8347	53100351	Equipo para bomba de infusion	Pieza
8348	53100352	Equipo para cuantificacion de auto anticuerpos	Pieza
8349	53100353	Equipo para determinacion de glucosa; colesterol y trigliceridos	Pieza
8350	53100354	Equipo para dialisis peritoneal	Pieza
8351	53100355	Equipo para drenaje de la cavidad	Pieza
8352	53100356	Equipo para drenaje por aspiracion	Pieza
8353	53100357	Equipo para hemodialisis	Pieza
8354	53100358	Equipo para irrigacion	Pieza
8355	53100359	Equipo para la deteccion de anticuerpos	Pieza
8356	53100360	Equipo para venoclisis	Pieza
8357	53100361	Equipo resucitador	Pieza
8358	53100362	Equipos de cateteres	Pieza
8359	53100363	Escaner de cama	Pieza
8360	53100364	Infantometro	Pieza
8361	53100365	Inspirometro	Pieza
8362	53100366	Insuflador	Pieza
8363	53100367	Lensometro	Pieza
8364	53100368	Pararrayos o apartarrayos	Pieza
8365	53100369	Plantoscopio	Pieza
8366	53100370	Pletismografo	Pieza
8367	53100371	Pleurovac	Pieza
8368	53100372	Plumilla para electroencefalografo	Pieza
8369	53100373	Prolongador	Pieza
8370	53100374	Recuperador	Pieza
8371	53100375	Respirador	Pieza
8372	53100376	Rinoscopio	Pieza
8373	53100377	Saturometro	Pieza
8374	53100378	Sillon	Pieza
8375	53100379	Centrifuga (aparato cientifico)	Pieza
8376	53100380	Amalgamador (aparato cientifico)	Pieza
8377	53100381	Endoscopio (aparato cientifico)	Pieza
8378	53100382	Termometro	Pieza
8379	53100383	Autoanalizador de nutrientes	Pieza
8380	53100384	Equipo de sanitizacion	Pieza
8381	53100385	Tina de hidroterapia	Pieza
8382	53100386	Piscina para terapia	Pieza
8383	53100387	Analizador biometrico	Pieza
8384	53100388	Angiografo	Pieza
8385	53100389	Equipo para astroscopia	Pieza
8386	53100390	Unidad de imagen por resonancia magnetica	Pieza
8387	53100391	Unidad para ultrasonografia	Pieza
8388	53100392	Acelerador lineal	Pieza
8389	53100393	Calorimetro (instrumento cientifico)	Pieza
8390	53100394	Camara salina (instrumento cientifico)	Pieza
8391	53100395	Compensador (aparato cientifico)	Pieza
8392	53100396	Desviador rotario o rotatorio (instrumento cientifico)	Pieza
8393	53100397	Disco drenador (instrumento cientifico)	Pieza
8394	53100398	Electro-dermatomo (aparato cientifico)	Pieza
8395	53100399	Emisor intervalo media (aparato cientifico)	Pieza
8396	53100400	Equipo acustica (aparato cientifico)	Pieza
8397	53100401	Equipo electroforesis (aparato cientifico)	Pieza
8398	53100402	Equipo medir revenimiento (aparato cientifico)	Pieza
8399	53100403	Equipo platinizar celdas de electrodos (aparato cientifico)	Pieza
8400	53100404	Espesometro o regla rayos x (instrumento cientifico)	Pieza
8401	53100405	Estanque (fijo)	Pieza
8402	53100406	Extractor acidos-alcalinos (aparato cientifico)	Pieza
8403	53100407	Heliografo (aparato cientifico)	Pieza
8404	53100408	Interferometro (instrumento cientifico)	Pieza
8405	53100409	Lente protector rayos ultravioleta (instrumento cientifico)	Pieza
8406	53100410	Medidor de espesores (instrumento cientifico)	Pieza
8407	53100411	Medidor demostrador (instrumento cientifico)	Pieza
8408	53100412	Medidor peso especifico (instrumento cientifico)	Pieza
8409	53100413	Medidor resistencia (esfuerzo sobre vigas, puentes,etc) (instrumento cientifico)	Pieza
8410	53100414	Membrana determinacion marchitamientos suelos (plato) (aparato cientifico)	Pieza
8411	53100415	Mira-micrometrica estadal (instrumento cientifico)	Pieza
8412	53100416	Penetrometro (instrumento cientifico)	Pieza
8413	53100417	Plastometro (instrumento cientifico)	Pieza
8414	53100418	Refractor (aparato cientifico)	Pieza
8415	53100419	Regulador oxigeno (aparato cientifico)	Pieza
8416	53100420	Retinoscopio (instrumento cientifico)	Pieza
8417	53100421	Seccionador (instrumento cientifico)	Pieza
8418	53100422	Simulador de procesos de produccion bajo control aut. (sist. Integ. de manufactura.)	Pieza
8419	53100423	Sincronizador (aparato cientifico)	Pieza
8420	53100424	Sonometro (instrumento cientifico)	Pieza
8421	53100425	Taquimetro (instrumento cientifico)	Pieza
8422	53100426	Telemetro (instrumento cientifico)	Pieza
8423	53100427	Termo cauterio (aparato cientifico)	Pieza
8424	53100428	Termo pluviometro (aparato cientifico)	Pieza
8425	53100429	Termohidrografo (aparato cientifico)	Pieza
8426	53100430	Tubo geissler (instrumento cientifico)	Pieza
8427	53100431	Turbidimetro (instrumento cientifico)	Pieza
8428	53100432	Unidad refrigeracion (aparato cientifico)	Pieza
8429	53100433	Vaporizador facial con lampara ozono	Pieza
8430	53100434	Voltimetro (instrumento cientifico)	Pieza
8431	53100435	Vumetro (instrumento cientifico)	Pieza
8432	53100436	Actinometro (instrumento cientifico)	Pieza
8433	53100437	Alcoholimetro (instrumento cientifico)	Pieza
8434	53100438	Alimentador (suministro o dosificado de compuestos quim. secos) ) (aparato cientifico)	Pieza
8435	53100439	Anemometro (instrumento cientifico)	Pieza
8436	53100440	Aparato desbastador (aparato cientifico)	Pieza
8437	53100441	Aparato disecacion (aparato cientifico)	Pieza
8438	53100442	Aparato generador gas (aparato cientifico)	Pieza
8439	53100443	Aparato newton (disco) (aparato cientifico)	Pieza
8440	53100444	Aparato propagacion de presion (aparato cientifico)	Pieza
8441	53100445	Aparato trazador señales (aparato cientifico)	Pieza
8442	53100446	Aspiradora (aparato cientifico)	Pieza
8443	53100447	Banco pruebas suelos (aparato cientifico)	Pieza
8444	53100448	Calibrador oftalmologia (instrumento cientifico)	Pieza
8445	53100449	Equipo e instrumental para mediciones de propiedades mecanicas	Pieza
8446	53100450	Camara hiperbarica (aparato cientifico)	Pieza
8447	53100451	Camara vacio (aparato cientifico)	Pieza
8448	53100452	Cilindro pooter (instrumento cientifico)	Pieza
8449	53100453	Cinta petrolera (instrumento cientifico)	Pieza
8450	53100454	Colorimetro (instrumento cientifico)	Pieza
8451	53100455	Comparador octeto (instrumento cientifico)	Pieza
8452	53100456	Contador colonias (instrumento cientifico)	Pieza
8453	53100457	Contador corriente electrica (instrumento cientifico)	Pieza
8454	53100458	Criostato (aparato cientifico)	Pieza
8455	53100459	Cronografo (aparato cientifico)	Pieza
8456	53100460	Decada condensadores y resistencias (instrumento cientifico)	Pieza
8457	53100461	Densimetro (instrumento cientifico)	Pieza
8458	53100462	Detector fugas de gas o agua (aparato cientifico)	Pieza
8459	53100463	Difractrometro (instrumento cientifico)	Pieza
8460	53100464	Dilutor laboratorio (instrumento cientifico)	Pieza
8461	53100465	Equipo conductividad hidraulica (aparato cientifico)	Pieza
8462	53100466	Equipo hidraulico (para practicas de control hidraulico) (instrumento cientifico)	Pieza
8463	53100467	Escalador (aparato cientifico)	Pieza
8464	53100468	Esclerometro (instrumento cientifico)	Pieza
8465	53100469	Espectro-fotometro (instrumento cientifico)	Pieza
8466	53100470	Exoftalmometro (instrumento cientifico)	Pieza
8467	53100471	Generador pulsos (aparato cientifico)	Pieza
8468	53100472	Higrometro (instrumento cientifico)	Pieza
8469	53100473	Hipsometro (instrumento cientifico)	Pieza
8470	53100474	Histerometro (instrumento cientifico)	Pieza
8471	53100475	Jaula faraday (aparato cientifico)	Pieza
8472	53100476	Juego compas (cientifico) (instrumento cientifico)	Pieza
8473	53100477	Liofilizadora (aparato cientifico)	Pieza
8474	53100478	Luxometro (instrumento cientifico)	Pieza
8475	53100479	Medidor presion (instrumento cientifico)	Pieza
8476	53100480	Medidor temperatura y calor (instrumento cientifico)	Pieza
8477	53100481	Mesa de granito (nivelada para hacer mediciones) (instrumento cientifico)	Pieza
8478	53100482	Metronomo (instrumento cientifico)	Pieza
8479	53100483	Micro-lector tubos hematocrito (instrumento cientifico)	Pieza
8480	53100484	Milivoltimetro (instrumento cientifico)	Pieza
8481	53100485	Osmometro (instrumento cientifico)	Pieza
8482	53100486	Panendoscopio (aparato cientifico)	Pieza
8483	53100487	Pirometro (instrumento cientifico)	Pieza
8484	53100488	Pluviografo (instrumento cientifico)	Pieza
8485	53100489	Potenciometro (instrumento cientifico)	Pieza
8486	53100490	Presurizador (aparato cientifico)	Pieza
8487	53100491	Probador manometro (aparato cientifico)	Pieza
8488	53100492	Probador medidores de agua (aparato cientifico)	Pieza
8489	53100493	Probador toberas (aparato cientifico)	Pieza
8490	53100494	Receptor facsimil de comportamiento atmosferico (aparato cientifico)	Pieza
8491	53100495	Refractometro (instrumento cientifico)	Pieza
8492	53100496	Respirometro (instrumento cientifico)	Pieza
8493	53100497	Revelador dinaflect (instrumento cientifico)	Pieza
8494	53100498	Telescopio (instrumento cientifico)	Pieza
8495	53100499	Teletermografo (instrumento cientifico)	Pieza
8496	53100500	Termoanemometro (sensor de temperatura) (instrumento cientifico)	Pieza
8497	53100501	Texturometro (instrumento cientifico)	Pieza
8498	53100502	Transportador tres brazos (instrumento cientifico)	Pieza
8499	53100503	Tubo newton (instrumento cientifico)	Pieza
8500	53100504	Vibrograbadora (instrumento cientifico)	Pieza
8501	53100505	Vibrografo (instrumento cientifico)	Pieza
8502	53100506	Videografo (aparato cientifico)	Pieza
8503	53100507	Watthorimetro (instrumento cientifico)	Pieza
8504	53100508	Wattimetro (instrumento cientifico)	Pieza
8505	53100509	Adaptador absorcion (aparato cientifico)	Pieza
8506	53100510	Aparato destilacion (aparato cientifico)	Pieza
8507	53100511	Aparato determinacion carbon en el aceite lubricante (aparato cientifico)	Pieza
8508	53100512	Aparato determinacion hidrogeno (aparato cientifico)	Pieza
8509	53100513	Aparato flujo fluido (aparato cientifico)	Pieza
8510	53100514	Aparato longitudes ondas electromagneticas (aparato cientifico)	Pieza
8511	53100515	Aparato medidor volumenes en peso seco (aparato cientifico)	Pieza
8512	53100516	Aparato obtencion extractos de saturacion de pastas y suelos (aparato cientifico)	Pieza
8513	53100517	Aparato prueba deformidad del cemento (aparato cientifico)	Pieza
8514	53100518	Aparato rayos ultravioleta (aparato cientifico)	Pieza
8515	53100519	Aparato recirculacion de refrigerante (aparato cientifico)	Pieza
8516	53100520	Aparato rociador (aparato cientifico)	Pieza
8517	53100521	Barometro (instrumento cientifico)	Pieza
8518	53100522	Caja diafanoscopica (instrumento cientifico)	Pieza
8519	53100523	Camara de neubauer	Pieza
8520	53100524	Probador de polaridad	Pieza
8521	53100525	Equipo e instrumental para mediciones de biologia	Pieza
8522	53100526	Equipo e instrumental para mediciones de densidad	Pieza
8523	53100527	Camara ionizacion (aparato cientifico)	Pieza
8524	53100528	Camara para endoscopio (aparato cientifico)	Pieza
8525	53100529	Cilindro decantacion (instrumento cientifico)	Pieza
8526	53100530	Contador geiger (instrumento cientifico)	Pieza
8527	53100531	Cromatografo (aparato cientifico)	Pieza
8528	53100532	Disco colorimetrico comparador laboratorio (instrumento cientifico)	Pieza
8529	53100533	Equipo angulo timon magistral (instrumento cientifico)	Pieza
8530	53100534	Equipo biologia (aparato cientifico)	Pieza
8531	53100535	Equipo de neumatica (para practicas de control neumatico) (instrumento cientifico)	Pieza
8532	53100536	Espectro fotografo (aparato cientifico)	Pieza
8533	53100537	Espectrometro (instrumento cientifico)	Pieza
8534	53100538	Estadimetro (instrumento cientifico)	Pieza
8535	53100539	Estuche normografo (instrumento cientifico)	Pieza
8536	53100540	Evaporador rotatorio (aparato cientifico)	Pieza
8537	53100541	Extractor fibra (aparato cientifico)	Pieza
8538	53100542	Fotomicroscopio (aparato cientifico)	Pieza
8539	53100543	Hidrometro (instrumento cientifico)	Pieza
8540	53100544	Inclinometro (instrumento cientifico)	Pieza
8541	53100545	Indicador velocidad laboratorio (instrumento cientifico)	Pieza
8542	53100546	Limpiadora (aparato cientifico)	Pieza
8543	53100547	Manometro (instrumento cientifico)	Pieza
8544	53100548	Medidor intensidad (instrumento cientifico)	Pieza
8545	53100549	Microscopio binocular (instrumento cientifico)	Pieza
8546	53100550	Modelo de arco para arco (simulador de arcos en estructura) (instrumento cientifico)	Pieza
8547	53100551	Mueble coleccion entomologica (aparato cientifico)	Pieza
8548	53100552	Muestreador (instrumento cientifico)	Pieza
8549	53100553	Odometro (instrumento cientifico)	Pieza
8550	53100554	Polipotomo (instrumento cientifico)	Pieza
8551	53100555	Probador cloro (aparato cientifico)	Pieza
8552	53100556	Probador gases (aparato cientifico)	Pieza
8553	53100557	Proyector de perfiles (verifica perfiles y contornos de piezas) (instrumento cientifico)	Pieza
8554	53100558	Quistotomo (aparato cientifico)	Pieza
8555	53100559	Regla calculo (instrumento cientifico)	Pieza
8556	53100560	Rotametro (instrumento cientifico)	Pieza
8557	53100561	Sismografo (aparato cientifico)	Pieza
8558	53100562	Sistema de microondas para calentamiento (instrumental de laboratorio)	Pieza
8559	53100563	Torre tablero plancheta (instrumento cientifico)	Pieza
8560	53100564	Transformador pruebas (instrumento cientifico)	Pieza
8561	53100565	Troboscopio (instrumento cientifico)	Pieza
8562	53100566	Turbina axial radial combinada (instrumento cientifico)	Pieza
8563	53100567	Veleta o rosa de los vientos (instrumento cientifico)	Pieza
8564	53100568	Verificador micrometro (aparato cientifico)	Pieza
8565	53100569	Viscosimetro (instrumento cientifico)	Pieza
8566	53100570	Acelerador de particulas (aparato cientifico)	Pieza
8567	53100571	Alveografo (aparato cientifico)	Pieza
8568	53100572	Aparato deflector (aparato cientifico)	Pieza
8569	53100573	Aparato medicion deformaciones modulo de concreto (aparato cientifico)	Pieza
8570	53100574	Aparato pascal (aparato cientifico)	Pieza
8571	53100575	Aparato presion capilar (aparato cientifico)	Pieza
8572	53100576	Aparato pruebas combustibles (aparato cientifico)	Pieza
8573	53100577	Aplicador bromuro de metilo (instrumento cientifico)	Pieza
8574	53100578	Baño precision (aparato) (aparato cientifico)	Pieza
8575	53100579	Bomba de vacio (aparato cientifico)	Pieza
8576	53100580	Equipo e instrumental para mediciones de temperatura	Pieza
8577	53100581	Equipo e instrumental para mediciones de cantidad de sustancia	Pieza
8578	53100582	Equipo e instrumental para mediciones de intensidad de corriente	Pieza
8579	53100583	Equipo e instrumental para mediciones de propiedades fisicas	Pieza
8580	53100584	Equipo e instrumental para mediciones de acustica	Pieza
8581	53100585	Equipo e instrumental para mediciones de radiometria	Pieza
8582	53100586	Equipo e instrumental para mediciones de flujo	Pieza
8583	53100587	Equipo e instrumental para mediciones de fuerza	Pieza
8584	53100588	Equipo e instrumental para mediciones de longitud	Pieza
8585	53100589	Camara de cultivo (instrumento cientifico)	Pieza
8586	53100590	Camara de inoculacion (instrumento cientifico)	Pieza
8587	53100591	Camara submarina (aparato cientifico)	Pieza
8588	53100592	Cilindro muestras laboratorio (instrumento cientifico)	Pieza
8589	53100593	Cilindro protector con accesorios (instrumento cientifico)	Pieza
8590	53100594	Computador aereo (aparato cientifico)	Pieza
8591	53100595	Contador vehiculos (instrumento cientifico)	Pieza
8592	53100596	Control amplitud oleaje (instrumento cientifico)	Pieza
8593	53100597	Control nivel calderas (aparato cientifico)	Pieza
8594	53100598	Determinador de impurezas (instrumento cientifico)	Pieza
8595	53100599	Distanciometro (instrumento cientifico)	Pieza
8596	53100600	Divisor (separador muestras) (aparato cientifico)	Pieza
8597	53100601	Dosificador (instrumento cientifico)	Pieza
8598	53100602	Electrofono (aparato cientifico)	Pieza
8599	53100603	Equipo para determinar proteinas (equipo kjendalh) (instrumento cientifico)	Pieza
8600	53100604	Estereografo (instrumento cientifico)	Pieza
8601	53100605	Estuche navegacion (juego de) (instrumento cientifico)	Pieza
8602	53100606	Evapotranspirometro (instrumento cientifico)	Pieza
8603	53100607	Fonendoscopio (aparato cientifico)	Pieza
8604	53100608	Foto fluorografo (instrumento cientifico)	Pieza
8605	53100609	Fotometro (instrumento cientifico)	Pieza
8606	53100610	Fotomultiplicador (aparato cientifico)	Pieza
8607	53100611	Generador frecuencia acustica (aparato cientifico)	Pieza
8608	53100612	Indicador viraje avion (instrumento cientifico)	Pieza
8609	53100613	Lampara microscopio (instrumento cientifico)	Pieza
8610	53100614	Lente telescopio (instrumento cientifico)	Pieza
8611	53100615	Medidor corriente electrica (instrumento cientifico)	Pieza
8612	53100616	Medidor oxigeno (instrumento cientifico)	Pieza
8613	53100617	Medidor transistores (instrumento cientifico)	Pieza
8614	53100618	Molino de muestras (aparato cientifico)	Pieza
8615	53100619	Polaroscopio (instrumento cientifico)	Pieza
8616	53100620	Porosimetro (instrumento cientifico)	Pieza
8617	53100621	Pulidora (aparato cientifico)	Pieza
8618	53100622	Radiometro (instrumento cientifico)	Pieza
8619	53100623	Ranurador prueba limite liquido (instrumento cientifico)	Pieza
8620	53100624	Rueda metal medir (instrumento cientifico)	Pieza
8621	53100625	Secuenciometro (aparato cientifico)	Pieza
8622	53100626	Tensiometro (instrumento cientifico)	Pieza
8623	53100627	Teodolito o transito (aparato cientifico)	Pieza
8624	53100628	Termografo (instrumento cientifico)	Pieza
8625	53100629	Torno cortar especimenes (instrumento cientifico)	Pieza
8626	53100630	Torre metereologica (instrumento cientifico)	Pieza
8627	53100631	Transductor (aparato cientifico)	Pieza
8628	53100632	Transmisor indicador angulo timon aparato de gobierno (aparato cientifico)	Pieza
8629	53100633	Transportador ingenieria (instrumento cientifico)	Pieza
8630	53100634	Altimetro (instrumento cientifico)	Pieza
8631	53100635	Aparato aplicador de alta frecuencia para tratamiento corporal	Pieza
8632	53100636	Aparato control remoto (aparato cientifico)	Pieza
8633	53100637	Aparato determinacion equivalente de la arena (aparato cientifico)	Pieza
8634	53100638	Aparato digestor (aparato cientifico)	Pieza
8635	53100639	Aparato filtrar y regular aire en concreto o cemento (aparato cientifico)	Pieza
8636	53100640	Aparato para determinar el regimen de fluido (reinols) (instrumento cientifico)	Pieza
8637	53100641	Balanza (cientifico) (instrumento cientifico)	Pieza
8638	53100642	Probador de fase	Pieza
8639	53100643	Equipo e instrumental para mediciones de propiedades electricas	Pieza
8640	53100644	Equipo e instrumental para mediciones de termometria	Pieza
8641	53100645	Equipo e instrumental para mediciones emergentes	Pieza
8642	53100646	Camara de incubacion (aparato cientifico)	Pieza
8643	53100647	Clasificador granulometrico (aparato cientifico)	Pieza
8644	53100648	Compas magnetico (instrumento cientifico)	Pieza
8645	53100649	Cortadora especimenes roca (aparato cientifico)	Pieza
8646	53100650	Cuenta celulas (instrumento cientifico)	Pieza
8647	53100651	Densitometro y balanza densidad (instrumento cientifico)	Pieza
8648	53100652	Desecador (aparato cientifico)	Pieza
8649	53100653	Detector metales (aparato cientifico)	Pieza
8650	53100654	Determinador soporte terraceria (instrumento cientifico)	Pieza
8651	53100655	Diapason (aparato cientifico)	Pieza
8652	53100656	Disco calculos (matematicos) (instrumento cientifico)	Pieza
8653	53100657	Disco reticula hilos cruzados (instrumento cientifico)	Pieza
8654	53100658	Discriminador (instrumento cientifico)	Pieza
8655	53100659	Dispositivo limites de contraccion (aparato cientifico)	Pieza
8656	53100660	Electrobalanza (aparato cientifico)	Pieza
8657	53100661	Electro-coagulador (aparato cientifico)	Pieza
8658	53100662	Equipo portatil determinacion de parametros ambientales (aparato cientifico)	Pieza
8659	53100663	Equipo termologia (aparato cientifico)	Pieza
8660	53100664	Espectroscopio (aparato cientifico)	Pieza
8661	53100665	Evaporimetro (instrumento cientifico)	Pieza
8662	53100666	Grabadora registro (aparato cientifico)	Pieza
8663	53100667	Graficadora (aparato cientifico)	Pieza
8664	53100668	Horno (instrumento cientifico)	Pieza
8665	53100669	Indicador velocidad ascenso y descenso avion (variometro) (instrumento cientifico)	Pieza
8666	53100670	Maquina aire liquido (aparato cientifico)	Pieza
8667	53100671	Medidor concentracion ionica fluor (aparato cientifico)	Pieza
8668	53100672	Microamperimetro (instrumento cientifico)	Pieza
8669	53100673	Microcentrifuga (aparato cientifico)	Pieza
8670	53100674	Microsoldadura (instrumento cientifico)	Pieza
8671	53100675	Oximetro (instrumento cientifico)	Pieza
8672	53100676	Placa lectura escalas fotometricas (instrumento cientifico)	Pieza
8673	53100677	Prensa manual montar especimenes (aparato cientifico)	Pieza
8674	53100678	Procesador digital para sismografo (aparato cientifico)	Pieza
8675	53100679	Registrador con tablero control transistorizado (instrumento cientifico)	Pieza
8676	53100680	Regulador aire (aparato cientifico)	Pieza
8677	53100681	Regulador diferencial de mercurio (aparato cientifico)	Pieza
8678	53100682	Repetidor giroscopica (instrumento cientifico)	Pieza
8679	53100683	Rugocimetro (aparato cientifico)	Pieza
8680	53100684	Tina probadora elementos filtrantes (aparato cientifico)	Pieza
8681	53100685	Tonometro (instrumento cientifico)	Pieza
8682	53100686	Torquimico (instrumento cientifico)	Pieza
8683	53100687	Trazador curvas (instrumento cientifico)	Pieza
8684	53100688	Tubo torriceli (instrumento cientifico)	Pieza
8685	53100689	Unidad ultrasonica (aparato cientifico)	Pieza
8686	53100690	Vernier pie de rey (instrumento cientifico)	Pieza
8687	53100691	Acelerador de van de graff (aparato cientifico)	Pieza
8688	53100692	Aparato automatico coloreador (aparato cientifico)	Pieza
8689	53100693	Aparato dispersion suelos (aparato cientifico)	Pieza
8690	53100694	Aparato extraccion (gases y liquidos) (aparato cientifico)	Pieza
8691	53100695	Aparato fusion termolyne (aparato cientifico)	Pieza
8692	53100696	Aparato pruebas floculacion (aparato cientifico)	Pieza
8693	53100697	Aspersora (aparato cientifico)	Pieza
8694	53100698	Banco riel (experimentos opticos) (aparato cientifico)	Pieza
8695	53100699	Equipo e instrumental para mediciones electromagneticas	Pieza
8696	53100700	Equipo e instrumental para mediciones de frecuencia	Pieza
8697	53100701	Equipo e instrumental para mediciones de volumen	Pieza
8698	53100702	Equipo e instrumental para mediciones de dimensiones	Pieza
8699	53100703	Campimetro (instrumento cientifico)	Pieza
8700	53100704	Celda puente conductibilidad electrica (instrumento cientifico)	Pieza
8701	53100705	Clorinador (aparato cientifico)	Pieza
8702	53100706	Compas ojo (instrumento cientifico)	Pieza
8703	53100707	Elipsografo (aparato cientifico)	Pieza
8704	53100708	Equipo campo obscuro (aparato cientifico)	Pieza
8705	53100709	Equipo prueba dureza del agua (aparato cientifico)	Pieza
8706	53100710	Equipo separaciones electroforeticas (aparato cientifico)	Pieza
8707	53100711	Ergometro (instrumento cientifico)	Pieza
8708	53100712	Estanque (armable)	Pieza
8709	53100713	Extensometro (instrumento cientifico)	Pieza
8710	53100714	Gausometro-degausometro (instrumento cientifico)	Pieza
8711	53100715	Goniometro (instrumento cientifico)	Pieza
8712	53100716	Heliotropo (instrumento cientifico)	Pieza
8713	53100717	Incubadora bacterias (aparato cientifico)	Pieza
8714	53100718	Limnigrafo (instrumento cientifico)	Pieza
8715	53100719	Maquina para hacer pruebas de tension y compresion (instrumento cientifico)	Pieza
8716	53100720	Masajeador corporal bio-electrico	Pieza
8717	53100721	Medidor agua (instrumento cientifico)	Pieza
8718	53100722	Medidor factor potencia (instrumento cientifico)	Pieza
8719	53100723	Microscopia monocular (instrumento cientifico)	Pieza
8720	53100724	Osciloscopio (aparato cientifico)	Pieza
8721	53100725	Paralelas mecanicas (instrumento cientifico)	Pieza
8722	53100726	Partidor muestras (instrumento cientifico)	Pieza
8723	53100727	Peachimetro (instrumento cientifico)	Pieza
8724	53100728	Placa compactacion (instrumento cientifico)	Pieza
8725	53100729	Pluviometro (instrumento cientifico)	Pieza
8726	53100730	Programador (aparato cientifico)	Pieza
8727	53100731	Radio compas aeronavegacion (instrumento cientifico)	Pieza
8728	53100732	Regleta geologia (instrumento cientifico)	Pieza
8729	53100733	Separador fluidos (aparato cientifico)	Pieza
8730	53100734	Shunt electrico o apartadero (instrumento cientifico)	Pieza
8731	53100735	Tornillo micrometrico (instrumento cientifico)	Pieza
8732	53100736	Urofluorometro (instrumento cientifico)	Pieza
8733	53100737	Vacuometro (instrumento cientifico)	Pieza
8734	53100738	Actinografo (aparato cientifico)	Pieza
8735	53100739	Agitador rotatorio tubos (aparato cientifico)	Pieza
8736	53100740	Alveolotomo (aparato cientifico)	Pieza
8737	53100741	Analizador de emisiones de motores a gasolina (instrumento cientifico)	Pieza
8738	53100742	Analizador gas (aparato cientifico)	Pieza
8739	53100743	Antropometro (aparato cientifico)	Pieza
8740	53100744	Aparato compresion para camara (aparato cientifico)	Pieza
8741	53100745	Aparato determinacion estabilidad turbosina (aparato cientifico)	Pieza
8742	53100746	Aparato fotoelectrico (aparato cientifico)	Pieza
8743	53100747	Aparato fuerza centrifuga (aparato cientifico)	Pieza
8744	53100748	Aparato provocar lluvia artificial (aparato cientifico)	Pieza
8745	53100749	Audiometro (instrumento cientifico)	Pieza
8746	53100750	Baumanometro (instrumento cientifico)	Pieza
8747	53100751	Caja regletas triangulacion (instrumento cientifico)	Pieza
8748	53100752	Calentador electrico de piedras para tratamiento corporal	Pieza
8749	53100753	Equipo e instrumental para mediciones de vibraciones	Pieza
8750	53100754	Equipo e instrumental para mediciones de velocidad	Pieza
8751	53100755	Clisimetro (instrumento cientifico)	Pieza
8752	53100756	Conductimetro (instrumento cientifico)	Pieza
8753	53100757	Cono viento tela (instrumento cientifico)	Pieza
8754	53100758	Contador golpes (instrumento cientifico)	Pieza
8755	53100759	Cronometro (instrumento cientifico)	Pieza
8756	53100760	Detector pozo profundo (aparato cientifico)	Pieza
8757	53100761	Dosimetro (instrumento cientifico)	Pieza
8758	53100762	Electro megafono (instrumento cientifico)	Pieza
8759	53100763	Entrenador para estudio de tiempos (instrumento cientifico)	Pieza
8760	53100764	Escandallo (instrumento cientifico)	Pieza
8761	53100765	Estereomicroscopio (aparato cientifico)	Pieza
8762	53100766	Esterilizador o autoclave (aparato cientifico)	Pieza
8763	53100767	Estroboscopio (instrumento cientifico)	Pieza
8764	53100768	Extractor grasa (aparato cientifico)	Pieza
8765	53100769	Filtro piezometrico (aparato cientifico)	Pieza
8766	53100770	Fluoroscopio (aparato cientifico)	Pieza
8767	53100771	Frecuencimetro (instrumento cientifico)	Pieza
8768	53100772	Galvanocauterio (aparato cientifico)	Pieza
8769	53100773	Generador de funciones (instrumento cientifico)	Pieza
8770	53100774	Jeringa ingenieria (instrumento cientifico)	Pieza
8771	53100775	Localizador fallas (aparato cientifico)	Pieza
8772	53100776	Magnetometro (instrumento cientifico)	Pieza
8773	53100777	Medidor r.h. (instrumento cientifico)	Pieza
8774	53100778	Megohmetro (instrumento cientifico)	Pieza
8775	53100779	Mesa de fluidez (para practicas en laboratorio) (instrumento cientifico)	Pieza
8776	53100780	Micromolino (instrumento cientifico)	Pieza
8777	53100781	Micronebulizador (aparato cientifico)	Pieza
8778	53100782	Microscopio operaciones (instrumento cientifico)	Pieza
8779	53100783	Micro-switch (instrumento cientifico)	Pieza
8780	53100784	Molinete eletrico (instrumento cientifico)	Pieza
8781	53100785	Nebulizador (instrumento cientifico)	Pieza
8782	53100786	Ocular (instrumento cientifico)	Pieza
8783	53100787	Olla presion (aparato cientifico)	Pieza
8784	53100788	Permeametro (instrumento cientifico)	Pieza
8785	53100789	Pulsor luces velocidad (aparato cientifico)	Pieza
8786	53100790	Radiocompas (instrumento cientifico)	Pieza
8787	53100791	Regla medicion electronica (instrumento cientifico)	Pieza
8788	53100792	Regulador acetileno (aparato cientifico)	Pieza
8789	53100793	Sincrografo (aparato cientifico)	Pieza
8790	53100794	Termometro (instrumento cientifico)	Pieza
8791	53100795	Termostato (aparato cientifico)	Pieza
8792	53100796	Vibrador (aparato cientifico)	Pieza
8793	53100797	Voltamperimetro (instrumento cientifico)	Pieza
8794	53100798	Absorbedor (instrumento cientifico)	Pieza
8795	53100799	Aerator (aparato cientifico)	Pieza
8796	53100800	Aparato aforo (aparato cientifico)	Pieza
8797	53100801	Aparato determinacion limite de liquido (suelos) (aparato cientifico)	Pieza
8798	53100802	Aparato electrolisis (aparato cientifico)	Pieza
8799	53100803	Aparato lavar plumillas -ultrasonico (aparato cientifico)	Pieza
8800	53100804	Aparato medidor bario (aparato cientifico)	Pieza
8801	53100805	Aparato para medir humedad y densidad de suelos (instrumento cientifico)	Pieza
8802	53100806	Aparato punto inflamacion combustibles (aparato cientifico)	Pieza
8803	53100807	Equipo e instrumental para mediciones de matriz natural	Pieza
8804	53100808	Camara maduracion (aparato cientifico)	Pieza
8805	53100809	Campana de gauss (aparato cientifico)	Pieza
8806	53100810	Cinta topografica (instrumento cientifico)	Pieza
8807	53100811	Contador cabeza oftalmoscopio (instrumento cientifico)	Pieza
8808	53100812	Desfibrilador (aparato cientifico)	Pieza
8809	53100813	Destilador nitrogeno (aparato cientifico)	Pieza
8810	53100814	Detector sismologico de campo (aparato cientifico)	Pieza
8811	53100815	Dinamometro (instrumento cientifico)	Pieza
8812	53100816	Durometro (instrumento cientifico)	Pieza
8813	53100817	Electro fotometro (instrumento cientifico)	Pieza
8814	53100818	Electrometro (instrumento cientifico)	Pieza
8815	53100819	Emisor rayos laser (aparato cientifico)	Pieza
8816	53100820	Equipo exploracion geoelectrica (aparato cientifico)	Pieza
8817	53100821	Equipo lab-trol (aparato cientifico)	Pieza
8818	53100822	Estacion mecanica (aparato cientifico)	Pieza
8819	53100823	Estadal (instrumento cientifico)	Pieza
8820	53100824	Exhibidor pantalla rayos catodicos (instrumento cientifico)	Pieza
8821	53100825	Fluorometro (instrumento cientifico)	Pieza
8822	53100826	Foto-colorimetro (instrumento cientifico)	Pieza
8823	53100827	Homogeneizador (aparato cientifico)	Pieza
8824	53100828	Microtomo (aparato cientifico)	Pieza
8825	53100829	Multimetro (instrumento cientifico)	Pieza
8826	53100830	Perfilografo (aparato cientifico)	Pieza
8827	53100831	Polarimetro (instrumento cientifico)	Pieza
8828	53100832	Polimetro (instrumento cientifico)	Pieza
8829	53100833	Probador lodos (aparato cientifico)	Pieza
8830	53100834	Profundimetro (instrumento cientifico)	Pieza
8831	53100835	Psicrometro (aparato cientifico)	Pieza
8832	53100836	Puente electrico (instrumento cientifico)	Pieza
8833	53100837	Pulmotor (aparato cientifico)	Pieza
8834	53100838	Pulverizador (aparato cientifico)	Pieza
8835	53100839	Registrador electrico pozos (instrumento cientifico)	Pieza
8836	53100840	Registrador nivel con computadora (instrumento cientifico)	Pieza
8837	53100841	Regulador estabilizador de voltaje (aparato cientifico)	Pieza
8838	53100842	Reloj (instrumento cientifico)	Pieza
8839	53100843	Reloj intervalos (instrumento cientifico)	Pieza
8840	53100844	Separador de grasas (instrumento cientifico)	Pieza
8841	53100845	Termometro electronico digital (instrumento cientifico)	Pieza
8842	53100846	Unidad alarma giroscopica (aparato cientifico)	Pieza
8843	53100847	Volumetro (instrumento cientifico)	Pieza
8844	53100848	Accesorios para equipo de perforacion para analisis de suelos (instrumento cientifico)	Pieza
8845	53100849	Agitador magnetico (aparato cientifico)	Pieza
8846	53100850	Agitador pipetas (aparato cientifico)	Pieza
8847	53100851	Amperimetro (instrumento cientifico)	Pieza
8848	53100852	Aparato control carbono (aparato cientifico)	Pieza
8849	53100853	Aparato inmunoelectroforesis (aparato cientifico)	Pieza
8850	53100854	Aparato lectura tacometro (instrumento cientifico)	Pieza
8851	53100855	Aparato ortofotografico (aparato cientifico)	Pieza
8852	53100856	Brujula (instrumento cientifico)	Pieza
8853	53100857	Calador (instrumental de laboratorio)	Pieza
8854	53100858	Equipo e instrumental para mediciones de radiofrecuencias	Pieza
8855	53100859	Equipo e instrumental para mediciones de optica	Pieza
8856	53100860	Equipo e instrumental para mediciones de propiedades quimicas	Pieza
8857	53100861	Equipo e instrumental para mediciones de presion	Pieza
8858	53100862	Equipo e instrumental para mediciones de masa	Pieza
8859	53100863	Equipo de quimica clinica	Pieza
8860	53100864	Central de monitoreo para pacientes	Pieza
8861	53100865	Laser para urologia	Pieza
8862	53100866	Generador de ondas de choque	Pieza
8863	53100867	Ortopantomografo	Pieza
8864	53100868	Torre de endourologia	Pieza
8865	53100869	Analizador de sangre	Pieza
8866	53100870	Colposcopio	Pieza
8867	53100871	Laser para oftalmologia	Pieza
8868	53100872	Laser endovascular	Pieza
8869	53100873	Laser fotocoagulador	Pieza
8870	53100874	Equipo para prueba de esfuerzo	Pieza
8871	53100875	Electrocardiografo ambulatorio	Pieza
8872	53100876	Estacion para lavado de instrumentos	Pieza
8873	53100877	Sistema de hidroseccion de heridas	Pieza
8874	53100878	Laser para otorrinolaringologia	Pieza
8875	53100879	Torre de endoscopia	Pieza
8876	53100880	Uteroscopio	Pieza
8877	53100881	Centro de inclusion de tejidos	Pieza
8878	53100882	Impedanciometro	Pieza
8879	53100883	Histeroscopio	Pieza
8880	53100884	Ultrasonido dental	Pieza
8881	53100885	Teñidor de histopatologia	Pieza
8882	53100886	Videolaringoscopio	Pieza
8883	53100887	Campana de flujo laminar	Pieza
8884	53100888	Cardiotocografo	Pieza
8885	53100889	Monitor de signos vitales	Pieza
8886	53100890	Acidimetro (instrumento cientifico)	Pieza
8887	53100891	Aerometro (instrumento cientifico)	Pieza
8888	53100892	Aforimetro (instrumento cientifico)	Pieza
8889	53100893	Aglutinoscopio (aparato cientifico)	Pieza
8890	53100894	Alacran (instrumento cientifico) (instrumento cientifico)	Pieza
8891	53100895	Alambique (aparato cientifico)	Pieza
8892	53100896	Albuminimetro (instrumento cientifico)	Pieza
8893	53100897	Alcalimetro (instrumento cientifico)	Pieza
8894	53100898	Alidada (instrumento cientifico)	Pieza
8895	53100899	Amoniador (instrumento cientifico)	Pieza
8896	53100900	Anemocinemografo (instrumento cientifico)	Pieza
8897	53100901	Anemografo (instrumento cientifico)	Pieza
8898	53100902	Aparato cavendish (aparato cientifico)	Pieza
8899	53100903	Aparato de fuerza centripeta (aparato cientifico)	Pieza
8900	53100904	Aparato de gauss yokogawa (aparato cientifico)	Pieza
8901	53100905	Aparato desague (aparato cientifico)	Pieza
8902	53100906	Aparato determinacion plasticidad hidraulica de suelos (aparato cientifico)	Pieza
8903	53100907	Aparato examen flotacion (aparato cientifico)	Pieza
8904	53100908	Aparato fenske (aparato cientifico)	Pieza
8905	53100909	Aparato gilmor (aparato cientifico)	Pieza
8906	53100910	Aparato medidor finura de cemento (aparato cientifico)	Pieza
8907	53100911	Aparato metalografico (aparato cientifico)	Pieza
8908	53100912	Aparato perfil ala de avion (aparato cientifico)	Pieza
8909	53100913	Aparato puntos relativos (aparato cientifico)	Pieza
8910	53100914	Aparato seybol (aparato cientifico)	Pieza
8911	53100915	Aparato silverman (aparato cientifico)	Pieza
8912	53100916	Aritmometro (aparato cientifico)	Pieza
8913	53100917	Astrolabio (instrumento cientifico)	Pieza
8914	53100918	Barografo (aparato cientifico)	Pieza
8915	53100919	Baroscopio (instrumento cientifico)	Pieza
8916	53100920	Batitermografo (instrumento cientifico)	Pieza
8917	53100921	Berilometro (instrumento cientifico)	Pieza
8918	53100922	Caleidoscopio (aparato cientifico)	Pieza
8919	53100923	Cilindro reposos evaporo metro (instrumento cientifico)	Pieza
8920	53100924	Cilindros cruzados p/oftalmologia (instrumento cientifico)	Pieza
8921	53100925	Circulo azimutal (instrumento cientifico)	Pieza
8922	53100926	Circulo marcacion (instrumento cientifico)	Pieza
8923	53100927	Cistometro (instrumento cientifico)	Pieza
8924	53100928	Colimador (instrumento cientifico)	Pieza
8925	53100929	Compresimetro (instrumento cientifico)	Pieza
8926	53100930	Consolimetro (aparato cientifico)	Pieza
8927	53100931	Contador trafico (aparato cientifico)	Pieza
8928	53100932	Coordinometro (instrumento cientifico)	Pieza
8929	53100933	Cortador semillas (aparato cientifico)	Pieza
8930	53100934	Cribadora (aparato cientifico)	Pieza
8931	53100935	Cronoscopio electronico (aparato cientifico)	Pieza
8932	53100936	Curvigrafo electronico (aparato cientifico)	Pieza
8933	53100937	Curvimetro (instrumento cientifico)	Pieza
8934	53100938	Deformimetro (instrumento cientifico)	Pieza
8935	53100939	Descascaradora (aparato cientifico)	Pieza
8936	53100940	Desmineralizador (aparato cientifico)	Pieza
8937	53100941	Desunificador (aparato cientifico)	Pieza
8938	53100942	Detector aflatoxinas (aparato cientifico)	Pieza
8939	53100943	Determinacion germinacion (vitascopio) (aparato cientifico)	Pieza
8940	53100944	Determinador azufre (aparato cientifico)	Pieza
8941	53100945	Dictafono (aparato cientifico)	Pieza
8942	53100946	Difusiometro (instrumento cientifico)	Pieza
8943	53100947	Digitador (instrumento cientifico)	Pieza
8944	53100948	Dilatometro (instrumento cientifico)	Pieza
8945	53100949	Dinametro (instrumento cientifico)	Pieza
8946	53100950	Dinamografo (aparato cientifico)	Pieza
8947	53100951	Ebullometro (instrumento cientifico)	Pieza
8948	53100952	Eclimetro (instrumento cientifico)	Pieza
8949	53100953	Episcopio (instrumento cientifico)	Pieza
8950	53100954	Equipo para pruebas de hermeticidad	Pieza
8951	53100955	Esferometro (instrumento cientifico)	Pieza
8952	53100956	Espectro colorimetro (instrumento cientifico)	Pieza
8953	53100957	Estereautografo (aparato cientifico)	Pieza
8954	53100958	Evaporigrafo (aparato cientifico)	Pieza
8955	53100959	Exposimetro (instrumento cientifico)	Pieza
8956	53100960	Fibrometro (instrumento cientifico)	Pieza
8957	53100961	Flamometro (instrumento cientifico)	Pieza
8958	53100962	Fototeodolito (aparato cientifico)	Pieza
8959	53100963	Fototurbo (aparato cientifico)	Pieza
8960	53100964	Galvanometro (instrumento cientifico)	Pieza
8961	53100965	Gasometro (instrumento cientifico)	Pieza
8962	53100966	Germinador (aparato cientifico)	Pieza
8963	53100967	Giroscopio (instrumento cientifico)	Pieza
8964	53100968	Globo kripton (aparato cientifico)	Pieza
8965	53100969	Grabadora pulsos (aparato cientifico)	Pieza
8966	53100970	Gradimetro (instrumento cientifico)	Pieza
8967	53100971	Gradiometro (instrumento cientifico)	Pieza
8968	53100972	Grafimetro (instrumento cientifico)	Pieza
8969	53100973	Grafometro (instrumento cientifico)	Pieza
8970	53100974	Gravimetro (instrumento cientifico)	Pieza
8971	53100975	Heliopirografo (aparato cientifico)	Pieza
8972	53100976	Hemisferios-magdeburgo (instrumento cientifico)	Pieza
8973	53100977	Hidrofono (eq. de reproduccion)	Pieza
8974	53100978	Hidroscopio (instrumento cientifico)	Pieza
8975	53100979	Hidrotermografo (aparato cientifico)	Pieza
8976	53100980	Higroscopio (instrumento cientifico)	Pieza
8977	53100981	Histerosalpingografo (instrumento cientifico)	Pieza
8978	53100982	Horometro (instrumento cientifico)	Pieza
8979	53100983	Humectador (aparato cientifico)	Pieza
8980	53100984	Ignitrometro (aparato cientifico)	Pieza
8981	53100985	Impedencimetro (instrumento cientifico)	Pieza
8982	54100046	Vagoneta	Pieza
8983	53100986	Inductometro (instrumento cientifico)	Pieza
8984	53100987	Instrumento medir el azimut (reloj acimutal) (instrumento cientifico)	Pieza
8985	53100988	Ionografo (aparato cientifico)	Pieza
8986	53100989	Joulimetro patron (instrumento cientifico)	Pieza
8987	53100990	Kilovatorimetro (instrumento cientifico)	Pieza
8988	53100991	Kimo-insuflador (aparato cientifico)	Pieza
8989	53100992	Lenzometro (instrumento cientifico)	Pieza
8990	53100993	Maquina atwood (instrumento cientifico)	Pieza
8991	53100994	Maquina para pruebas (Jolt, Jumble)	Pieza
8992	53100995	Mareografo o mareometro (instrumento cientifico)	Pieza
8993	53100996	Medidor millas nauticas (instrumento cientifico)	Pieza
8994	53100997	Megatometro (instrumento cientifico)	Pieza
8995	53100998	Metaloscopio (aparato cientifico)	Pieza
8996	53100999	Microrefractometro (instrumento cientifico)	Pieza
8997	53101000	Miliamperimetro (instrumento cientifico)	Pieza
8998	53101001	Mime-microgasometro (instrumento cientifico)	Pieza
8999	53101002	Octante (instrumento cientifico)	Pieza
9000	53101003	Ohmetro (instrumento cientifico)	Pieza
9001	53101004	Oleografo (aparato cientifico)	Pieza
9002	53101005	Oscilador (aparato cientifico)	Pieza
9003	53101006	Oscilografo (aparato cientifico)	Pieza
9004	53101007	Oscilometro (instrumento cientifico)	Pieza
9005	53101008	Osciloperturbografo (aparato cientifico)	Pieza
9006	53101009	Oxificador (aparato cientifico)	Pieza
9007	53101010	Pantoscopio (instrumento cientifico)	Pieza
9008	53101011	Pendulo (instrumento cientifico)	Pieza
9009	53101012	Pignometro (instrumento cientifico)	Pieza
9010	53101013	Plancheta (instrumento cientifico)	Pieza
9011	53101014	Planigrafo (instrumento cientifico)	Pieza
9012	53101015	Planimetro (instrumento cientifico)	Pieza
9013	53101016	Planta didactica de galvanoplastia (instrumento cientifico)	Pieza
9014	53101017	Polarografo (instrumento cientifico)	Pieza
9015	53101018	Probador angulos (aparato cientifico)	Pieza
9016	53101019	Puente doble kelvin (instrumento cientifico)	Pieza
9017	53101020	Q-metro (instrumento cientifico)	Pieza
9018	53101021	Quemador arteasificacion (aparato cientifico)	Pieza
9019	53101022	Queratomo (electrico) (aparato cientifico)	Pieza
9020	53101023	Raquinamometro (instrumento cientifico)	Pieza
9021	53101024	Rectoscopio (instrumento cientifico)	Pieza
9022	53101025	Relascopio (instrumento cientifico)	Pieza
9023	53101026	Rosa nautica (instrumento cientifico)	Pieza
9024	53101027	Sacarometro (instrumento cientifico)	Pieza
9025	53101028	Salimetro (instrumento cientifico)	Pieza
9026	53101029	Salpingografo (aparato cientifico)	Pieza
9027	53101030	Sembradora (aparato cientifico)	Pieza
9028	53101031	Separadora de cilindro (aparato cientifico)	Pieza
9029	53101032	Sextante (instrumento cientifico)	Pieza
9030	53101033	Sicrometro (instrumento cientifico)	Pieza
9031	53101034	Sinecroscopio (instrumento cientifico)	Pieza
9032	53101035	Sismometro (instrumento cientifico)	Pieza
9033	53101036	Sulfametro (instrumento cientifico)	Pieza
9034	53101037	Taximetro nautico (instrumento cientifico)	Pieza
9035	53101038	Telumetro (instrumento cientifico)	Pieza
9036	53101039	Tenografo (instrumento cientifico)	Pieza
9037	53101040	Termomagneto (aparato cientifico)	Pieza
9038	53101041	Terrametro (instrumento cientifico)	Pieza
9039	53101042	Tipometro (instrumento cientifico)	Pieza
9040	53101043	Titrometro (instrumento cientifico)	Pieza
9041	53101044	Ultramicrotomo (aparato cientifico)	Pieza
9042	53101045	Unigrafo (aparato cientifico)	Pieza
9043	53101046	Urinometro (instrumento cientifico)	Pieza
9044	53101047	Vectorscopio (instrumento cientifico)	Pieza
9045	53101048	Vectorscopio (señal de video) (instrumento cientifico)	Pieza
9046	53101049	Viacosimetro (instrumento cientifico)	Pieza
9047	53101050	Vitalometro (instrumento cientifico)	Pieza
9048	53101051	Voltametro (instrumento cientifico)	Pieza
9049	53101052	Equipo e instrumental para mediciones de tiempo	Pieza
9050	53101053	Equipo e instrumental para mediciones de intensidad luminosa	Pieza
9051	53101054	Equipo e instrumental para mediciones de pureza organica	Pieza
9052	53101055	Equipo e instrumental para mediciones de inorganica	Pieza
9053	53101056	Estacion meteorologica (toma mediciones de parametros meteorologicos) (instrumento cientifico)	Pieza
9054	53101057	Equipo para monitoreo de aguas profundas	Pieza
9055	53101058	Procesador de tejidos	Pieza
9056	53101059	Baño de flotacion	Pieza
9057	53101060	Estacion de trabajo para laboratorio	Pieza
9058	53101061	Placa sistema de enfriamiento	Pieza
9059	53101062	Placa para tratamiento termico	Pieza
9060	53101063	Equipo para toma de imagenes	Pieza
9061	53101064	Carro elevador para cadaveres	Pieza
9062	53101065	Equipo multifuncional para microcirugia	Pieza
9063	53101066	Analizador de gases para motores (instrumento cientifico)	Pieza
9064	53101067	Simulador de fallas para sistema de frenos (instrumento cientifico)	Pieza
9065	53101068	Equipo de almacenamiento rotativo para medicamentos y materiales	Pieza
9066	53101069	Equipo dispensador automatizado de medicamentos y materiales	Pieza
9067	53101070	Equipo auxiliar automatizado de medicamentos y materiales	Pieza
9068	53101071	Equipo de refrigeracion para medicamentos	Pieza
9069	53101072	Equipo automatizado de identificacion, corte y reenvasado en unidosis de blisteres de medicamentos	Pieza
9070	53101073	Equipo de reenvasado de medicamentos  a granel en dosis unitarias	Pieza
9071	53101074	Silla de ruedas motorizada	Pieza
9072	53101075	Camara de ahumado con cianocrilato	Pieza
9073	53101076	Estacion de trabajo forense	Pieza
9074	53101077	Equipo de aislamiento y proteccion del lugar de los hechos	Pieza
9075	53101078	Equipo para microencapsulacion	Pieza
9076	53101079	Equipo para necrocirugia	Pieza
9077	53101080	Dispositivo para sujecion de transductores	Pieza
9078	53101081	Olla electrica para fundir	Pieza
9079	53101082	Celda de carga	Pieza
9080	53101083	Aparato para depilacion	Pieza
9081	53101084	Aparato galvanico	Pieza
9082	53101085	Aparato presoterapia	Pieza
9083	53101086	Equipo para tratamiento estetico	Pieza
9084	53101087	Aparato para vibroterapia	Pieza
9085	53101088	Aparato mesoterapia	Pieza
9086	5320	Instrumental medico y de laboratorio	
9087	53201	Instrumental medico y de laboratorio	
9088	53200001	Abrebocas (equipo medico quirurgico)	Pieza
9089	53200002	Adaptador (instrumental de laboratorio)	Pieza
9090	53200003	Adenotomo (equipo medico quirurgico)	Pieza
9091	53200004	Amniotomo (equipo medico quirurgico)	Pieza
9092	53200005	Analizador de iones (instrumento cientifico)	Pieza
9093	53200006	Aparato de caida libre (instrumento cientifico)	Pieza
9094	53200007	Aparato de cowan (aparato cientifico)	Pieza
9095	53200008	Aparato de hofman (aparato cientifico)	Pieza
9096	53200009	Aparato de huygens (instrumento cientifico)	Pieza
9097	53200010	Aparato de oersted (instrumento cientifico)	Pieza
9098	53200011	Aparato para demostrar el centro de gravedad (aparato cientifico)	Pieza
9099	53200012	Aparato placa calefactora termo linea (instrumento cientifico)	Pieza
9100	53200013	Aparato sordera (equipo medico quirurgico)	Pieza
9101	53200014	Aplicador laringeo (equipo medico quirurgico)	Pieza
9102	53200015	Bandeja cuadrangular y forma riñon (equipo medico quirurgico)	Pieza
9103	53200016	Base nivel (placas) (equipo medico quirurgico)	Pieza
9104	53200017	Baston correccion (experimentos opticos) (equipo medico quirurgico)	Pieza
9105	53200018	Bolsa respiracion (equipo medico quirurgico)	Pieza
9106	53200019	Botador (equipo medico quirurgico)	Pieza
9107	53200020	Brazo opresor lentes opticos (equipo medico quirurgico)	Pieza
9108	53200021	Bujia esofagial (equipo medico quirurgico)	Pieza
9109	53200022	Bujia mercurio (equipo medico quirurgico)	Pieza
9110	53200023	Butirometro (equipo medico quirurgico)	Pieza
9111	53200024	Cabezal balancin (instrumento cientifico)	Pieza
9112	53200025	Caja de sustitucion de inductancia (instrumento cientifico)	Pieza
9113	53200026	Caja entomologica (equipo medico quirurgico)	Pieza
9114	53200027	Caja tension (instrumental de laboratorio)	Pieza
9115	53200028	Camilla marina (instrumental de laboratorio)	Pieza
9116	53200029	Canastilla calculos (instrumental de laboratorio)	Pieza
9117	53200030	Carro banco (experimentos opticos) (equipo medico quirurgico)	Pieza
9118	53200031	Charola diseccion (equipo medico quirurgico)	Pieza
9119	53200032	Charola esterilizacion membranas (equipo medico quirurgico)	Pieza
9120	53200033	Charola instrumental cirugia (equipo medico quirurgico)	Pieza
9121	53200034	Charola intestinal (equipo medico quirurgico)	Pieza
9122	53200035	Cincel p/hueso (equipo medico quirurgico)	Pieza
9123	53200036	Cistotomo (equipo medico quirurgico)	Pieza
9124	53200037	Clamp anastomosis intestinal (equipo medico quirurgico)	Pieza
9125	53200038	Clamp biopsia musculo (equipo medico quirurgico)	Pieza
9126	53200039	Clamp cardiovascular (equipo medico quirurgico)	Pieza
9127	53200040	Clamp circuncision (equipo medico quirurgico)	Pieza
9128	53200041	Clamp colon (equipo medico quirurgico)	Pieza
9129	53200042	Clamp conductor clavos (equipo medico quirurgico)	Pieza
9130	53200043	Clamp gastrointestinal (equipo medico quirurgico)	Pieza
9131	53200044	Clamp hueso (equipo medico quirurgico)	Pieza
9132	53200045	Clamp incontinencia (control enuresis) (equipo medico quirurgico)	Pieza
9133	53200046	Clamp ortopedico meniscos (equipo medico quirurgico)	Pieza
9134	53200047	Clamp retraccion parpados (equipo medico quirurgico)	Pieza
9135	53200048	Clamp septum reconstruccion plastica (equipo medico quirurgico)	Pieza
9136	53200049	Clamp sierra duodenal (equipo medico quirurgico)	Pieza
9137	53200050	Clamp stenosis pulmonar (equipo medico quirurgico)	Pieza
9138	53200051	Clip especimen roca (equipo medico quirurgico)	Pieza
9139	53200052	Collar opresor (experimentos opticos) (instrumental de laboratorio)	Pieza
9140	53200053	Comodo (equipo medico quirurgico)	Pieza
9141	53200054	Compresor orbita (equipo medico quirurgico)	Pieza
9142	53200055	Compresor rodillas (equipo medico quirurgico)	Pieza
9143	53200056	Conductor impactor placas (equipo medico quirurgico)	Pieza
9144	53200057	Conductor sondas (equipo medico quirurgico)	Pieza
9145	53200058	Conductor tendones (equipo medico quirurgico)	Pieza
9146	53200059	Conector (experimentos opticos) (equipo medico quirurgico)	Pieza
9147	53200060	Contra angulo excavador dental (equipo medico quirurgico)	Pieza
9148	53200061	Controlador de vacio (instrumento cientifico)	Pieza
9149	53200062	Costotomo ortopedico (equipo medico quirurgico)	Pieza
9150	53200063	Craneoplasto (equipo medico quirurgico)	Pieza
9151	53200064	Cucharilla antron (equipo medico quirurgico)	Pieza
9152	53200065	Cucharilla cadera (equipo medico quirurgico)	Pieza
9153	53200066	Cucharilla enucleacion (equipo medico quirurgico)	Pieza
9154	53200067	Cucharilla fusion espinal (equipo medico quirurgico)	Pieza
9155	53200068	Cucharilla glandula pituitaria (equipo medico quirurgico)	Pieza
9156	53200069	Cucharilla hueso (equipo medico quirurgico)	Pieza
9157	53200070	Cucharilla obstetrica (equipo medico quirurgico)	Pieza
9158	53200071	Cucharilla serumen (equipo medico quirurgico)	Pieza
9159	53200072	Cucharilla tirabolas (equipo medico quirurgico)	Pieza
9160	53200073	Cucharilla uterina (equipo medico quirurgico)	Pieza
9161	53200074	Cuchillo amputacion (equipo medico quirurgico)	Pieza
9162	53200075	Cuchillo angina (equipo medico quirurgico)	Pieza
9163	53200076	Cuchillo aracnoides (equipo medico quirurgico)	Pieza
9164	53200077	Cuchillo autopsia (equipo medico quirurgico)	Pieza
9165	53200078	Cuchillo cardotomia (equipo medico quirurgico)	Pieza
9166	53200079	Cuchillo cartilago (equipo medico quirurgico)	Pieza
9167	53200080	Cuchillo catarata (equipo medico quirurgico)	Pieza
9168	53200081	Cuchillo cerebro (equipo medico quirurgico)	Pieza
9169	53200082	Cuchillo corneal (equipo medico quirurgico)	Pieza
9170	53200083	Cuchillo cortar y remover yeso (equipo medico quirurgico)	Pieza
9171	53200084	Cuchillo electrico corte-coagulacion (equipo medico quirurgico)	Pieza
9172	53200085	Cuchillo esternon (equipo medico quirurgico)	Pieza
9173	53200086	Cuchillo fisura palatina (equipo medico quirurgico)	Pieza
9174	53200087	Cuchillo goniotomia (equipo medico quirurgico)	Pieza
9175	53200088	Cuchillo iris (equipo medico quirurgico)	Pieza
9176	53200089	Cuchillo laringeal (equipo medico quirurgico)	Pieza
9177	53200090	Cuchillo meniscos (equipo medico quirurgico)	Pieza
9178	53200091	Cuchillo mesa (equipo medico quirurgico)	Pieza
9179	53200092	Cuchillo microlaringe (equipo medico quirurgico)	Pieza
9180	53200093	Cuchillo miringotomia (equipo medico quirurgico)	Pieza
9181	53200094	Cuchillo mucosa (equipo medico quirurgico)	Pieza
9182	53200095	Cuchillo nasal (equipo medico quirurgico)	Pieza
9183	53200096	Cuchillo nervio (equipo medico quirurgico)	Pieza
9184	53200097	Cuchillo paracentesis (equipo medico quirurgico)	Pieza
9185	53200098	Cuchillo timpanoplastia (equipo medico quirurgico)	Pieza
9186	53200099	Cuchillo transplante (equipo medico quirurgico)	Pieza
9187	53200100	Cuchillo traqueotomia (equipo medico quirurgico)	Pieza
9188	53200101	Cuchillo vesicula biliar (equipo medico quirurgico)	Pieza
9189	53200102	Cusector amigdala (instrumental de laboratorio)	Pieza
9190	53200103	Desfibriladores medico quirurgicos (instrumental de laboratorio)	Pieza
9191	53200104	Desionizador (instrumento cientifico)	Pieza
9192	53200105	Dilatador vias lagrimales (equipo medico quirurgico)	Pieza
9193	53200106	Dilatador calculos biliares (equipo medico quirurgico)	Pieza
9194	53200107	Dilatador cardiaco (equipo medico quirurgico)	Pieza
9195	53200108	Dilatador esofagial (jgo. De) (equipo medico quirurgico)	Pieza
9196	53200109	Dilatador laringe (equipo medico quirurgico)	Pieza
9197	53200110	Dilatador traqueal (equipo medico quirurgico)	Pieza
9198	53200111	Dilatador uretral (equipo medico quirurgico)	Pieza
9199	53200112	Dilatador uterino (equipo medico quirurgico)	Pieza
9200	53200113	Disector corneal (equipo medico quirurgico)	Pieza
9201	53200114	Disector hipofisectomia (equipo medico quirurgico)	Pieza
9202	53200115	Disector hueso (equipo medico quirurgico)	Pieza
9203	53200116	Disector laringeal (equipo medico quirurgico)	Pieza
9204	53200117	Disector microcirugia (equipo medico quirurgico)	Pieza
9205	53200118	Disector neurocirugia (equipo medico quirurgico)	Pieza
9206	53200119	Disector oido interno (equipo medico quirurgico)	Pieza
9207	53200120	Disector oido medio (equipo medico quirurgico)	Pieza
9208	53200121	Disector septum nasal (equipo medico quirurgico)	Pieza
9209	53200122	Disector sesamoidectomia (equipo medico quirurgico)	Pieza
9210	53200123	Disector submucosas (equipo medico quirurgico)	Pieza
9211	53200124	Disector succion amigdala (equipo medico quirurgico)	Pieza
9212	53200125	Disector succion nasal (equipo medico quirurgico)	Pieza
9213	53200126	Diseñador puentes removibles (equipo medico quirurgico)	Pieza
9214	53200127	Electro iman manual (equipo medico quirurgico)	Pieza
9215	53200128	Elevador hueso (equipo medico quirurgico)	Pieza
9216	53200129	Elevador quirurgico (equipo medico quirurgico)	Pieza
9217	53200130	Enjuagador botellas (instrumental de laboratorio)	Pieza
9218	53200131	Equipo electrodos (instrumental de laboratorio)	Pieza
9219	53200132	Equipo metriset (instrumental de laboratorio)	Pieza
9220	53200133	Equipo para venoclisis (instrumental de laboratorio)	Pieza
9221	53200134	Equipo r.h. sangre (equipo medico quirurgico)	Pieza
9222	53200135	Equipo raquea (equipo medico quirurgico)	Pieza
9223	53200136	Esclerotomo (equipo medico quirurgico)	Pieza
9224	53200137	Escofina hueso (equipo medico quirurgico)	Pieza
9225	53200138	Escupidera (equipo medico quirurgico)	Pieza
9226	53200139	Espatula quirurgica (equipo medico quirurgico)	Pieza
9227	53200140	Espejo aglutinaciones (equipo medico quirurgico)	Pieza
9228	53200141	Espejo concavo y/o convexo (equipo medico quirurgico)	Pieza
9229	53200142	Espejo esferico (equipo medico quirurgico)	Pieza
9230	53200143	Espejo esternotomo (equipo medico quirurgico)	Pieza
9231	53200144	Espejo frontal (equipo medico quirurgico)	Pieza
9232	53200145	Espejo gonioscopia (equipo medico quirurgico)	Pieza
9233	53200146	Espejo laringeo (equipo medico quirurgico)	Pieza
9234	53200147	Espejo nasal (equipo medico quirurgico)	Pieza
9235	53200148	Espejo oido medio (equipo medico quirurgico)	Pieza
9236	53200149	Espejo plano (equipo medico quirurgico)	Pieza
9237	53200150	Espejo rectal (equipo medico quirurgico)	Pieza
9238	53200151	Espejo vaginal (equipo medico quirurgico)	Pieza
9239	53200152	Estetoscopio (instrumental de laboratorio)	Pieza
9240	53200153	Estilete conductos biliares (equipo medico quirurgico)	Pieza
9241	53200154	Estilete dentista (equipo medico quirurgico)	Pieza
9242	53200155	Estilete desjardin (equipo medico quirurgico)	Pieza
9243	53200156	Excavador dental (instrumental de laboratorio)	Pieza
9244	53200157	Extractor automatico (equipo medico quirurgico)	Pieza
9245	53200158	Extractor cabeza fetal (equipo medico quirurgico)	Pieza
9246	53200159	Extractor calculos (equipo medico quirurgico)	Pieza
9247	53200160	Eyector remolino tanque hidroterapia (equipo medico quirurgico)	Pieza
9248	53200161	Eyector saliva (equipo medico quirurgico)	Pieza
9249	53200162	Fetotomo (equipo medico quirurgico)	Pieza
9250	53200163	Filtro colorimetro (equipo medico quirurgico)	Pieza
9251	53200164	Forceps obstetrico (equipo medico quirurgico)	Pieza
9252	53200165	Fracturador (equipo medico quirurgico)	Pieza
9253	53200166	Gage de block (instrumento cientifico)	Pieza
9254	53200167	Gancho duramadre (equipo medico quirurgico)	Pieza
9255	53200168	Gancho estrabismo (equipo medico quirurgico)	Pieza
9256	53200169	Gancho extractor clavos (equipo medico quirurgico)	Pieza
9257	53200170	Gancho extractor protesis (equipo medico quirurgico)	Pieza
9258	53200171	Gancho kelly (equipo medico quirurgico)	Pieza
9259	53200172	Gancho musculo (equipo medico quirurgico)	Pieza
9260	53200173	Gancho separador parpados (equipo medico quirurgico)	Pieza
9261	53200174	Gancho traquea (equipo medico quirurgico)	Pieza
9262	53200175	Ganchos de prensa (instrumento cientifico)	Pieza
9263	53200176	Insectario (equipo medico quirurgico)	Pieza
9264	53200177	Intercambiador ion (equipo medico quirurgico)	Pieza
9265	53200178	Introductor clavo (equipo medico quirurgico)	Pieza
9266	53200179	Irrigador (equipo medico quirurgico)	Pieza
9267	53200180	Jarra anaerobica (equipo medico quirurgico)	Pieza
9268	53200181	Laboratorio portatil (instrumento cientifico)	Pieza
9269	53200182	Lampara catodo hueco (equipo medico quirurgico)	Pieza
9270	53200183	Lampara cistoscopio (equipo medico quirurgico)	Pieza
9271	53200184	Lanceta (mango) (equipo medico quirurgico)	Pieza
9272	53200185	Legra elevador (equipo medico quirurgico)	Pieza
9273	53200186	Legra espinal (equipo medico quirurgico)	Pieza
9274	53200187	Legra oido (equipo medico quirurgico)	Pieza
9275	53200188	Lima hueso (equipo medico quirurgico)	Pieza
9276	53200189	Limpiador dental (instrumental de laboratorio)	Pieza
9277	53200190	Magnetizador de brujulas (instrumento cientifico)	Pieza
9278	53200191	Maquina de instron (instrumento cientifico)	Pieza
9279	53200192	Martillo ortopedico (equipo medico quirurgico)	Pieza
9280	53200193	Martillo reflejos (equipo medico quirurgico)	Pieza
9281	53200194	Mascarilla anestesia (equipo medico quirurgico)	Pieza
9282	53200195	Mascarilla oxigeno (equipo medico quirurgico)	Pieza
9283	53200196	Medidor ocular (castroviejo) (instrumento cientifico)	Pieza
9284	53200197	Mesa soporte componentes opticos (con/sin graduacion) (instrumental de laboratorio)	Pieza
9285	53200198	Microscopios (instrumental de laboratorio)	Pieza
9286	53200199	Nucleador para obtencion de muestras de sedimentos marinos (aparato cientifico)	Pieza
9287	53200200	Obturador odontologia (equipo medico quirurgico)	Pieza
9288	53200201	Oftalmoscopio (instrumental de laboratorio)	Pieza
9289	53200202	Otoscopio (instrumental de laboratorio)	Pieza
9290	53200203	Piedra aereadora para acuarios de acuacultura (aparato cientifico)	Pieza
9291	53200204	Pinza adenoidectomia (equipo medico quirurgico)	Pieza
9292	53200205	Pinza alambrar protesis (equipo medico quirurgico)	Pieza
9293	53200206	Pinza amigdalotomia (equipo medico quirurgico)	Pieza
9294	53200207	Pinza anastomosis colon (equipo medico quirurgico)	Pieza
9295	53200208	Pinza anastomosis duodeno (equipo medico quirurgico)	Pieza
9296	53200209	Pinza anestesia laringe (equipo medico quirurgico)	Pieza
9297	53200210	Pinza aplicacion clips hemostasis (equipo medico quirurgico)	Pieza
9298	53200211	Pinza biopsia bronquios (equipo medico quirurgico)	Pieza
9299	53200212	Pinza biopsia endoscopia (equipo medico quirurgico)	Pieza
9300	53200213	Pinza biopsia esofago (equipo medico quirurgico)	Pieza
9301	53200214	Pinza biopsia urologia (equipo medico quirurgico)	Pieza
9302	53200215	Pinza biopsia uterina (equipo medico quirurgico)	Pieza
9303	53200216	Pinza blefarostato (equipo medico quirurgico)	Pieza
9304	53200217	Pinza broncoscopia y esofagos copia (equipo medico quirurgico)	Pieza
9305	53200218	Pinza campo operatorio (equipo medico quirurgico)	Pieza
9306	53200219	Pinza capsula (equipo medico quirurgico)	Pieza
9307	53200220	Pinza cartilago (equipo medico quirurgico)	Pieza
9308	53200221	Pinza castracion (burdizo) (equipo medico quirurgico)	Pieza
9309	53200222	Pinza cecostomia (equipo medico quirurgico)	Pieza
9310	53200223	Pinza cerilla (equipo medico quirurgico)	Pieza
9311	53200224	Pinza cerrar extraer alfileres seguridad (equipo medico quirurgico)	Pieza
9312	53200225	Pinza cirugia oido (equipo medico quirurgico)	Pieza
9313	53200226	Pinza coartacion arterial neurocirugia (equipo medico quirurgico)	Pieza
9314	53200227	Pinza coartacion cardiovascular (equipo medico quirurgico)	Pieza
9315	53200228	Pinza conducir sutura cirugia (equipo medico quirurgico)	Pieza
9316	53200229	Pinza coronaria (equipo medico quirurgico)	Pieza
9317	53200230	Pinza cortar clavo (equipo medico quirurgico)	Pieza
9318	53200231	Pinza cortar hueso (equipo medico quirurgico)	Pieza
9319	53200232	Pinza corte curvas (equipo medico quirurgico)	Pieza
9320	53200233	Pinza crimping (reparacion de circuitos) (equipo medico quirurgico)	Pieza
9321	53200234	Pinza cuchara anastomosis (equipo medico quirurgico)	Pieza
9322	53200235	Pinza curaciones neurologicas (equipo medico quirurgico)	Pieza
9323	53200236	Pinza curaciones odontologicas (equipo medico quirurgico)	Pieza
9324	53200237	Pinza curaciones oftalmologicas (equipo medico quirurgico)	Pieza
9325	53200238	Pinza curaciones oido y nariz (equipo medico quirurgico)	Pieza
9326	53200239	Pinza curaciones uterinas (equipo medico quirurgico)	Pieza
9327	53200240	Pinza dacrio cistorinostomia (equipo medico quirurgico)	Pieza
9328	53200241	Pinza dientes estriados (equipo medico quirurgico)	Pieza
9329	53200242	Pinza diseccion (equipo medico quirurgico)	Pieza
9330	53200243	Pinza diseccion y ligadura cardiovascular (equipo medico quirurgico)	Pieza
9331	53200244	Pinza doble matraz (equipo medico quirurgico)	Pieza
9332	53200245	Pinza extirpacion meniscos (equipo medico quirurgico)	Pieza
9333	53200246	Pinza extirpacion papiloma laringe (equipo medico quirurgico)	Pieza
9334	53200247	Pinza extirpacion polipos (equipo medico quirurgico)	Pieza
9335	53200248	Pinza extirpacion quistes (equipo medico quirurgico)	Pieza
9336	53200249	Pinza extraccion calculos (equipo medico quirurgico)	Pieza
9337	53200250	Pinza extraccion celulas etmoides (equipo medico quirurgico)	Pieza
9338	53200251	Pinza extraccion clavos ortopedia (equipo medico quirurgico)	Pieza
9339	53200252	Pinza extraccion dental (equipo medico quirurgico)	Pieza
9340	53200253	Pinza extraccion disco vertebral (equipo medico quirurgico)	Pieza
9341	53200254	Pinza extraccion tumor endocraneal (equipo medico quirurgico)	Pieza
9342	53200255	Pinza gastrointestinal (equipo medico quirurgico)	Pieza
9343	53200256	Pinza gubia (rascador oseo) (equipo medico quirurgico)	Pieza
9344	53200257	Pinza hemorroidal (equipo medico quirurgico)	Pieza
9345	53200258	Pinza hipofisectomia (equipo medico quirurgico)	Pieza
9346	53200259	Pinza histerectomia (equipo medico quirurgico)	Pieza
9347	53200260	Pinza hueso-cartilago cirugia plastica (equipo medico quirurgico)	Pieza
9348	53200261	Pinza introduccion tubo endotraqueal (equipo medico quirurgico)	Pieza
9349	53200262	Pinza iridectomia (equipo medico quirurgico)	Pieza
9350	53200263	Pinza laringea (equipo medico quirurgico)	Pieza
9351	53200264	Pinza litotritor (equipo medico quirurgico)	Pieza
9352	53200265	Pinza marcar bolsa ingivectomia (equipo medico quirurgico)	Pieza
9353	53200266	Pinza microarterial neurocirugia (equipo medico quirurgico)	Pieza
9354	53200267	Pinza microneurocirugia (equipo medico quirurgico)	Pieza
9355	53200268	Pinza microcirugia laringe (equipo medico quirurgico)	Pieza
9356	53200269	Pinza microcirugia oftalmologia (equipo medico quirurgico)	Pieza
9357	53200270	Pinza microcirugia oido externo (equipo medico quirurgico)	Pieza
9358	53200271	Pinza musculo (equipo medico quirurgico)	Pieza
9359	53200272	Pinza nefrologia (equipo medico quirurgico)	Pieza
9360	53200273	Pinza nuez doble (equipo medico quirurgico)	Pieza
9361	53200274	Pinza oclusion cardiovascular (equipo medico quirurgico)	Pieza
9362	53200275	Pinza ortopedica (equipo medico quirurgico)	Pieza
9363	53200276	Pinza perforacion vertebra (equipo medico quirurgico)	Pieza
9364	53200277	Pinza placenta (equipo medico quirurgico)	Pieza
9365	53200278	Pinza porta algodones rectal (equipo medico quirurgico)	Pieza
9366	53200279	Pinza prensar celofan (equipo medico quirurgico)	Pieza
9367	53200280	Pinza prostatectomia (equipo medico quirurgico)	Pieza
9368	53200281	Pinza puncion membrana fetal (equipo medico quirurgico)	Pieza
9369	53200282	Pinza puntos (equipo medico quirurgico)	Pieza
9370	53200283	Pinza rectal (equipo medico quirurgico)	Pieza
9371	53200284	Pinza refrigerante (equipo medico quirurgico)	Pieza
9372	53200285	Pinza remover grapa sutura (equipo medico quirurgico)	Pieza
9373	53200286	Pinza remover yeso ortopedia (equipo medico quirurgico)	Pieza
9374	53200287	Pinza reseccion hepatica (equipo medico quirurgico)	Pieza
9375	53200288	Pinza secuestrectomia (equipo medico quirurgico)	Pieza
9376	53200289	Pinza separar vertebra (equipo medico quirurgico)	Pieza
9377	53200290	Pinza sosten componente tibial (equipo medico quirurgico)	Pieza
9378	53200291	Pinza sujecion bureta (equipo medico quirurgico)	Pieza
9379	53200292	Pinza sujecion cordon umbilical (equipo medico quirurgico)	Pieza
9380	53200293	Pinza sujecion pedicuro (equipo medico quirurgico)	Pieza
9381	53200294	Pinza sujecion piloro (equipo medico quirurgico)	Pieza
9382	53200295	Pinza sujecion y corte grapas sutura (equipo medico quirurgico)	Pieza
9383	53200296	Pinza sujetar tornillos (equipo medico quirurgico)	Pieza
9384	53200297	Pinza tejido cirugia general (equipo medico quirurgico)	Pieza
9385	53200298	Pinza tejidos cardiovasculares (equipo medico quirurgico)	Pieza
9386	53200299	Pinza tejidos dermoplastia (equipo medico quirurgico)	Pieza
9387	56300094	Perforadora para barrenar	Pieza
9388	53200300	Pinza tejidos intestinales (equipo medico quirurgico)	Pieza
9389	53200301	Pinza tejidos neurocirugia (equipo medico quirurgico)	Pieza
9390	53200302	Pinza tejidos odontologia (equipo medico quirurgico)	Pieza
9391	53200303	Pinza tejidos oftalmologia (equipo medico quirurgico)	Pieza
9392	53200304	Pinza tenoctomia (equipo medico quirurgico)	Pieza
9393	53200305	Pinza tira-lenguas (equipo medico quirurgico)	Pieza
9394	53200306	Pinza tiroidectomia parcial (equipo medico quirurgico)	Pieza
9395	53200307	Pinza transportar instrumental quirurgico (equipo medico quirurgico)	Pieza
9396	53200308	Pinza trasplante cornea (equipo medico quirurgico)	Pieza
9397	53200309	Pinza trituracion yeso ortopedia (equipo medico quirurgico)	Pieza
9398	53200310	Pinza union hueso ortopedia (equipo medico quirurgico)	Pieza
9399	53200311	Pinza universal (equipo medico quirurgico)	Pieza
9400	53200312	Pinza vaginal (equipo medico quirurgico)	Pieza
9401	53200313	Pinza vaso de precipitado (equipo medico quirurgico)	Pieza
9402	53200314	Pinzas de crisol (equipo medico quirurgico)	Pieza
9403	53200315	Pinzas de kelly (equipo medico quirurgico)	Pieza
9404	53200316	Pinzas de mosquito (equipo medico quirurgico)	Pieza
9405	53200317	Porta muestras eda (instrumental de laboratorio)	Pieza
9406	53200318	Propipeta automatica (instrumento cientifico)	Pieza
9407	53200319	Proporcionador amalgama y mercurio (equipo medico quirurgico)	Pieza
9408	53200320	Punzon ortopedico (equipo medico quirurgico)	Pieza
9409	53200321	Radiacion de shielo (instrumento cientifico)	Pieza
9410	53200322	Raspa uterina (equipo medico quirurgico)	Pieza
9411	53200323	Reactor cood. (instrumento cientifico)	Pieza
9412	53200324	Recortador amalgama (instrumental de laboratorio)	Pieza
9413	53200325	Removedor puentes y coronas (equipo medico quirurgico)	Pieza
9414	53200326	Restirador entomologico (instrumental de laboratorio)	Pieza
9415	53200327	Retractor iris (equipo medico quirurgico)	Pieza
9416	53200328	Retractor lagrimal (equipo medico quirurgico)	Pieza
9417	53200329	Retractor laminectomia (equipo medico quirurgico)	Pieza
9418	53200330	Retractor pilar (equipo medico quirurgico)	Pieza
9419	53200331	Retractor rodillas (equipo medico quirurgico)	Pieza
9420	53200332	Retractor tiroides (equipo medico quirurgico)	Pieza
9421	53200333	Riel de colisiones (instrumento cientifico)	Pieza
9422	53200334	Rotor mano excavacion dental (equipo medico quirurgico)	Pieza
9423	53200335	Safenotomo (equipo medico quirurgico)	Pieza
9424	53200336	Separador abdominal (equipo medico quirurgico)	Pieza
9425	53200337	Separador amputacion (equipo medico quirurgico)	Pieza
9426	53200338	Separador anal (equipo medico quirurgico)	Pieza
9427	53200339	Separador bucal (equipo medico quirurgico)	Pieza
9428	53200340	Separador cerebro (equipo medico quirurgico)	Pieza
9429	53200341	Separador cirugia general (equipo medico quirurgico)	Pieza
9430	53200342	Separador cirugia plastica (equipo medico quirurgico)	Pieza
9431	53200343	Separador columna (equipo medico quirurgico)	Pieza
9432	53200344	Separador costilla (equipo medico quirurgico)	Pieza
9433	53200345	Separador esternon (equipo medico quirurgico)	Pieza
9434	53200346	Separador femurlla (equipo medico quirurgico)	Pieza
9435	53200347	Separador nasal (equipo medico quirurgico)	Pieza
9436	53200348	Separador nervio (equipo medico quirurgico)	Pieza
9437	53200349	Separador orbital (equipo medico quirurgico)	Pieza
9438	53200350	Separador otorrino (equipo medico quirurgico)	Pieza
9439	53200351	Separador pediatrico (equipo medico quirurgico)	Pieza
9440	53200352	Separador piel (equipo medico quirurgico)	Pieza
9441	53200353	Separador prostatico (equipo medico quirurgico)	Pieza
9442	53200354	Separador pulmonar (equipo medico quirurgico)	Pieza
9443	53200355	Separador rectal (equipo medico quirurgico)	Pieza
9444	53200356	Separador retropubico (equipo medico quirurgico)	Pieza
9445	53200357	Separador tibia (equipo medico quirurgico)	Pieza
9446	53200358	Separador tiroides (equipo medico quirurgico)	Pieza
9447	53200359	Separador vaginal (equipo medico quirurgico)	Pieza
9448	53200360	Separador vejiga (equipo medico quirurgico)	Pieza
9449	53200361	Separador ventriculografia (equipo medico quirurgico)	Pieza
9450	53200362	Separador yeso (equipo medico quirurgico)	Pieza
9451	53200363	Sistema de osmosis inversa milli-ro (instrumento cientifico)	Pieza
9452	53200364	Sistema purificador de agua (milli "q") (instrumento cientifico)	Pieza
9453	53200365	Soporte para muestras (equipo medico quirurgico)	Pieza
9454	53200366	Soporte porta filtros (equipo medico quirurgico)	Pieza
9455	53200367	Sujetador (pinza, experimentos opticos) (equipo medico quirurgico)	Pieza
9456	53200368	Termo par (instrumento cientifico)	Pieza
9457	53200369	Termometro visual no programable (instrumental de laboratorio)	Pieza
9458	53200370	Termometro visual programable (instrumental de laboratorio)	Pieza
9459	53200371	Tijera abdominal (equipo medico quirurgico)	Pieza
9460	53200372	Tijera alambre (equipo medico quirurgico)	Pieza
9461	53200373	Tijera amigdalas (equipo medico quirurgico)	Pieza
9462	53200374	Tijera arteria (equipo medico quirurgico)	Pieza
9463	53200375	Tijera arteriotomia (equipo medico quirurgico)	Pieza
9464	53200376	Tijera cardiovascular (equipo medico quirurgico)	Pieza
9465	53200377	Tijera cartilago semilunar (equipo medico quirurgico)	Pieza
9466	53200378	Tijera cirugia general (equipo medico quirurgico)	Pieza
9467	53200379	Tijera cirugia plastica (equipo medico quirurgico)	Pieza
9468	53200380	Tijera clavo (equipo medico quirurgico)	Pieza
9469	53200381	Tijera clips sutura (equipo medico quirurgico)	Pieza
9470	53200382	Tijera corneal (equipo medico quirurgico)	Pieza
9471	53200383	Tijera cuticular (cirugia general) (equipo medico quirurgico)	Pieza
9472	53200384	Tijera de mayo (equipo medico quirurgico)	Pieza
9473	53200385	Tijera diseccion (cirugia general) (equipo medico quirurgico)	Pieza
9474	53200386	Tijera diseccion pulmonar (equipo medico quirurgico)	Pieza
9475	53200387	Tijera enucleacion (equipo medico quirurgico)	Pieza
9476	53200388	Tijera episiotomia (equipo medico quirurgico)	Pieza
9477	53200389	Tijera esofageal (equipo medico quirurgico)	Pieza
9478	53200390	Tijera estrabismo (equipo medico quirurgico)	Pieza
9479	53200391	Tijera gasa (equipo medico quirurgico)	Pieza
9480	53200392	Tijera histeroscopia (equipo medico quirurgico)	Pieza
9481	53200393	Tijera iridocapsulotomia (equipo medico quirurgico)	Pieza
9482	53200394	Tijera iris (equipo medico quirurgico)	Pieza
9483	53200395	Tijera laringeal (equipo medico quirurgico)	Pieza
9484	53200396	Tijera lobectomia (equipo medico quirurgico)	Pieza
9485	53200397	Tijera membrana pupilar (equipo medico quirurgico)	Pieza
9486	53200398	Tijera menisectomia (equipo medico quirurgico)	Pieza
9487	53200399	Tijera microcirugia general (equipo medico quirurgico)	Pieza
9488	53200400	Tijera microcirugia oido (equipo medico quirurgico)	Pieza
9489	53200401	Tijera microconjuntiva (equipo medico quirurgico)	Pieza
9490	53200402	Tijera microcorneal (equipo medico quirurgico)	Pieza
9491	53200403	Tijera microsutura (equipo medico quirurgico)	Pieza
9492	53200404	Tijera microtenotomia (equipo medico quirurgico)	Pieza
9493	53200405	Tijera nasal (equipo medico quirurgico)	Pieza
9494	53200406	Tijera oido medio (equipo medico quirurgico)	Pieza
9495	53200407	Tijera pediatrica (equipo medico quirurgico)	Pieza
9496	53200408	Tijera reconstruccion plastica (equipo medico quirurgico)	Pieza
9497	53200409	Tijera rectal (equipo medico quirurgico)	Pieza
9498	53200410	Tijera septum (equipo medico quirurgico)	Pieza
9499	53200411	Tijera sutura ojo (equipo medico quirurgico)	Pieza
9500	53200412	Tijera tecnotomia (equipo medico quirurgico)	Pieza
9501	53200413	Tijera toraxica-cardiovascular (equipo medico quirurgico)	Pieza
9502	53200414	Tijera tumor (equipo medico quirurgico)	Pieza
9503	53200415	Tijera umbilical (equipo medico quirurgico)	Pieza
9504	53200416	Tijera uterina (equipo medico quirurgico)	Pieza
9505	53200417	Tijera vascular (equipo medico quirurgico)	Pieza
9506	53200418	Tijera venda (equipo medico quirurgico)	Pieza
9507	53200419	Tijera vesicula biliar (equipo medico quirurgico)	Pieza
9508	53200420	Tijeras cataratas (equipo medico quirurgico)	Pieza
9509	53200421	Torniquete cardiovascular (equipo medico quirurgico)	Pieza
9510	53200422	Torniquete neumatico (equipo medico quirurgico)	Pieza
9511	53200423	Tractor quirurgico (instrumental de laboratorio)	Pieza
9512	53200424	Trocar punsion, curvas y rectas (equipo medico quirurgico)	Pieza
9513	53200425	Uretromo (instrumental de laboratorio)	Pieza
9514	53200426	Anoscopio  (equipo medico quirurgico)	Pieza
9515	53200427	Barboteador (equipo medico quirurgico)	Pieza
9516	53200428	Baumanometro (equipo medico quirurgico)	Pieza
9517	53200429	Engrapadora (equipo medico quirurgico)	Pieza
9518	53200430	Esfinterotomo (equipo medico quirurgico)	Pieza
9519	53200431	Espaciador (instrumental medico y de laboratorio)	Pieza
9520	53200432	Espiral (instrumental medico y de laboratorio)	Pieza
9521	53200433	Fijador (equipo medico quirurgico)	Pieza
9522	53200434	Gancho (equipo medico quirurgico)	Pieza
9523	53200435	Guias (instrumental medico)	Pieza
9524	53200436	Perforador (equipo medico quirurgico)	Pieza
9525	53200438	Pinza (equipo medico quirurgico)	Pieza
9526	53200439	Porta matriz (equipo medico quirurgico)	Pieza
9527	53200440	Posicionador de cabeza (equipo medico quirurgico)	Pieza
9528	53200441	Reometro (equipo medico quirurgico)	Pieza
9529	53200442	Videonistagmografo (equipo medico quirurgico)	Pieza
9530	53200443	Paralelometro	Pieza
9531	53200444	Localizador de venas	Pieza
9532	5400	Vehiculos y equipo de transporte	
9533	5410	Vehiculos y equipo terrestre	
9534	54101	Vehiculos y equipo terrestres, para la ejecucion de programas de seguridad publica y nacional	
9535	54100060	Vehiculo militar	Pieza
9536	54102	Vehiculos y equipo terrestres, destinados exclusivamente para desastres naturales	
9537	54103	Vehiculos y equipo terrestres, destinados a servicios publicos y la operacion de programas publicos	
9538	54100001	Ambulancia	Pieza
9539	54100002	Automovil convertible	Pieza
9540	54100003	Automovil coupe	Pieza
9541	54100004	Automovil sedan	Pieza
9542	54100005	Barredora	Pieza
9543	54100006	Camion blindado (guardavalores)	Pieza
9544	54100007	Camion caja	Pieza
9545	54100008	Camion celdillas	Pieza
9546	54100009	Camion chassis- cabina	Pieza
9547	54100010	Camion de bomberos	Pieza
9548	54100011	Camion doble traccion	Pieza
9549	54100012	Camion grua	Pieza
9550	54100013	Camion laboratorio	Pieza
9551	54100014	Camion malacate (winche)	Pieza
9552	54100015	Camion media oruga	Pieza
9553	54100016	Camion panel	Pieza
9554	54100017	Camion pantanos	Pieza
9555	54100018	Camion pick-up	Pieza
9556	54100019	Camion plataforma	Pieza
9557	54100020	Camion recolector de basura	Pieza
9558	54100021	Camion redilas	Pieza
9559	54100022	Camion refrigerador	Pieza
9560	54100023	Camion revolvedora	Pieza
9561	54100024	Camion tanque (pipa)	Pieza
9562	54100025	Camion unidad de t.v.	Pieza
9563	54100026	Camion volteo	Pieza
9564	54100027	Camioneta (guayin, panel, estacas-redilas)	Pieza
9565	54100028	Carro blindado de reconocimiento y transporte	Pieza
9566	54100029	Carros de pasajeros (comedor, dormitorio)	Pieza
9567	54100030	Carros de plataforma	Pieza
9568	54100031	Carros tanque	Pieza
9569	54100032	Carroza	Pieza
9570	54100033	Casa remolque	Pieza
9571	54100034	Cisterna (vehiculo)	Pieza
9572	54100035	Dragas terrestres	Pieza
9573	54100036	Eductores (aspiradora para drenaje)	Pieza
9574	54100037	Empujador	Pieza
9575	54100038	Jeep	Pieza
9576	54100039	Limousine	Pieza
9577	54100040	Microbus	Pieza
9578	54100041	Omnibus o autobus convencional	Pieza
9579	54100042	Omnibus o autobus de turismo	Pieza
9580	54100043	Omnibus o autobus panoramico	Pieza
9581	54100044	Omnibus o autobus tropical	Pieza
9582	54104	Vehiculos y equipo terrestres, destinados a servicios administrativos	
9583	54105	Vehiculos y equipo terrestres, destinados a servidores publicos	
9584	5420	Carrocerias y remolques	
9585	54201	Carrocerias y remolques	
9586	54200001	Armones	Pieza
9587	54200002	Cabrestante	Pieza
9588	54200003	Cabuses	Pieza
9589	54200004	Caja (camion volteo)	Pieza
9590	54200005	Caja para tractor (trailer)	Pieza
9591	54200006	Carreta	Pieza
9592	54200007	Carro lateral para motocicleta	Pieza
9593	54200008	Carro minero	Pieza
9594	54200009	Carro para balasto	Pieza
9595	54200010	Carros (caja, tolva y jaula)	Pieza
9596	54200011	Chasis	Pieza
9597	54200012	Cisterna para tractor (trailer)	Pieza
9598	54200013	Plataforma brazo hidraulico	Pieza
9599	54200014	Plataforma con escalera	Pieza
9600	54200015	Plataforma con perforadora	Pieza
9601	54200016	Plataforma para carros de ferrocarril	Pieza
9602	54200017	Remolcador	Pieza
9603	54200018	Remolque basculante	Pieza
9604	54200019	Remolque cama baja	Pieza
9605	54200020	Remolque cisterna	Pieza
9606	54200021	Remolque plataforma	Pieza
9607	54200022	Remolque redilas	Pieza
9608	54200023	Remolque tipo para acampar	Pieza
9609	54200024	Remolque tolva	Pieza
9610	54200025	Remolque volteo	Pieza
9611	54200026	Semi-remolque	Pieza
9612	54200027	Tornapull o volquete	Pieza
9613	54200028	Tractocamion	Pieza
9614	54200029	Lorry simple	Pieza
9615	54200030	Lorry con pluma	Pieza
9616	5430	Equipo aeroespacial	
9617	54301	Vehiculos y equipo aereos, para la ejecucion de programas de seguridad publica y nacional	
9618	54302	Vehiculos y equipo aereos, destinados exclusivamente para desastres naturales	
9619	54303	Vehiculos y equipo aereos, destinados a servicios publicos y la operacion de programas publicos	
9620	54300001	Avion bimotor helice	Pieza
9621	54300002	Avion bimotor turbohelice	Pieza
9622	54300003	Avion bimotor turboreactor	Pieza
9623	54300004	Avion monomotor helice	Pieza
9624	54300005	Avion monomotor turboreactor	Pieza
9625	54300006	Avion tetramotor helice	Pieza
9626	54300007	Avion tetramotor turbohelice	Pieza
9627	54300008	Avion tetramotor turboreactor	Pieza
9628	54300009	Avion trimotor helice	Pieza
9629	54300010	Avion trimotor turboreactor	Pieza
9630	54300011	Equipo especial inflar llantas de avion	Pieza
9631	54300012	Helicoptero bimotor helice	Pieza
9632	54300013	Helicoptero bimotor turbohelice	Pieza
9633	54300014	Helicoptero monomotor helice	Pieza
9634	54300015	Helicoptero trimotor turbohelice	Pieza
9635	54300016	Helicoptero turbohelice	Pieza
9636	54300017	Hidroavion monomotor helice	Pieza
9637	54300018	Hidroavion tetramotor turbohelice	Pieza
9638	54300019	Tijera remolcar helicopteros	Pieza
9639	54300020	Tractores de arrastre de aviones	Pieza
9640	54300021	Vehiculo aereo no tripulado	Pieza
9641	54300022	Depositos externos de combustible para aeronaves	Pieza
9642	54300023	Pilones para cargas externas de aeronaves	Pieza
9643	5440	Equipo ferroviario	
9644	54401	Equipo ferroviario	
9645	54400001	Carro pasajeros (metro)	Pieza
9646	54400002	Grua ferroviaria	Pieza
9647	54400003	Locomotora	Pieza
9648	54400004	Tractor (metro)	Pieza
9649	54400005	Tractor ferroviario	Pieza
9650	54400006	Transbordador	Pieza
9651	54400007	Tranvia	Pieza
9652	54400008	Trolebus	Pieza
9653	5450	Embarcaciones	
9654	54501	Vehiculos y equipo maritimo, para la ejecucion de programas de seguridad publica y nacional	
9655	54500100	Embarcacion de rescate	Pieza
9656	54502	Vehiculos y equipo maritimo, destinados a servicios publicos y la operacion de programas publicos	
9657	54500001	Anfibio bimotor helice	Pieza
9658	54500002	Anfibio monomotor helice	Pieza
9659	54500003	Anfibio tetramotor turbohelice	Pieza
9660	54500004	Balsa inflable	Pieza
9661	54500005	Barco pasajeros	Pieza
9662	54500006	Barco pesquero	Pieza
9663	54500007	Buque carga	Pieza
9664	54500008	Buque tanque	Pieza
9665	54500009	Canoa	Pieza
9666	54500010	Carro gondola	Pieza
9667	54500011	Casa flotante	Pieza
9668	54500012	Chalan	Pieza
9669	54500013	Draga marina	Pieza
9670	54500014	Esquife	Pieza
9671	54500015	Lancha	Pieza
9672	54500016	Remolque para lancha (vehiculo no automotor)	Pieza
9673	54500017	Vehiculo acuatico con equipo para inspeccion submarina (instrumento cientifico)	Pieza
9674	54500018	Velero	Pieza
9675	54500019	Falua	Pieza
9676	54500020	Ganguil	Pieza
9677	54500021	Ponton	Pieza
9678	54500022	Boya	Pieza
9679	54500023	Embarcacion	Pieza
9680	54503	Construccion de embarcaciones	
9681	54500300	Maquinaria y equipo para armado y ensamblado de embarcaciones	Pieza
9682	5490	Otros equipos de transporte	
9683	54901	Otros equipos de transporte	
9684	54900001	Bicicleta	Pieza
9685	54900002	Carro transportacion campo de golf	Pieza
9686	54900003	Motocicleta	Pieza
9687	54900004	Motoneta	Pieza
9688	5500	Equipo de defensa y seguridad	
9689	5510	Equipo de defensa y seguridad	
9690	55101	Maquinaria y equipo de defensa y seguridad publica	
9691	55100001	Ametralladora (eq. O inst. Belico)	Pieza
9692	55100002	Aparato arreglo espoletas (eq. O inst. Belico)	Pieza
9693	55100003	Arcabuz (eq. O inst. Belico)	Pieza
9694	55100004	Autopatrulla	Pieza
9695	55100005	Bayoneta (eq. O inst. Belico)	Pieza
9696	55100006	Bazuca (eq. O inst. Belico)	Pieza
9697	55100007	Buque guerra	Pieza
9698	55100008	Camion militar	Pieza
9699	55100009	Camion tanque militar	Pieza
9700	55100010	Cañon mortero (eq. O inst. Belico)	Pieza
9701	55100011	Carabina (eq. O inst. Belico)	Pieza
9702	55100012	Cargador (eq. O inst. Belico)	Pieza
9703	55100013	Carro comando militar	Pieza
9704	55100014	Carro ligero de exploracion militar	Pieza
9705	55100015	Cureña (eq. O inst. Belico)	Pieza
9706	55100016	Escopeta (eq. O inst. Belico)	Pieza
9707	55100017	Escuadra (eq. O inst. Belico)	Pieza
9708	55100018	Espada c/s vaina (eq. O inst. Belico)	Pieza
9709	55100019	Espadin c/vaina (eq. O inst. Belico)	Pieza
9710	55100020	Espeton (eq. O inst. Belico)	Pieza
9711	55100021	Esponton c/vaina (eq. O inst. Belico)	Pieza
9712	55100022	Fusil (eq. O inst. Belico)	Pieza
9713	55100023	Fusil semiautomatico (eq. O inst. Belico)	Pieza
9714	55100024	Iluminador para pistola (eq. O inst. Belico)	Pieza
9715	55100025	Impulsor granada (eq. O inst. Belico)	Pieza
9716	55100026	Lanza dardo (atlatl) (eq. O inst. Belico)	Pieza
9717	55100027	Lanza llamas (eq. O inst. Belico)	Pieza
9718	55100028	Macana lanza-gas (eq. O inst. Belico)	Pieza
9719	55100029	Marcos moviles	Pieza
9720	55100030	Metralleta (eq. O inst. Belico)	Pieza
9721	55100031	Mira telescopica (eq. O inst. Belico)	Pieza
9722	55100032	Mosqueton (eq. O inst. Belico)	Pieza
9723	55100033	Pica (eq. O inst. Belico)	Pieza
9724	55100034	Pistola (diversos tipos y calibres) (eq. O inst. Belico)	Pieza
9725	55100035	Pistola de descarga de poder (eq. O inst. Belico)	Pieza
9726	55100036	Recargador de bateria para sistema laser de pistola (eq. O inst. Belico)	Pieza
9727	55100037	Revolver (eq. O inst. Belico)	Pieza
9728	55100038	Rifle (eq. O inst. Belico)	Pieza
9729	55100039	Robot electrico antibomba (eq. O inst. Belico)	Pieza
9730	55100040	Sable c/s vaina (eq. O inst. Belico)	Pieza
9731	55100041	Silenciador (eq. O inst. Belico)	Pieza
9732	55100042	Sistema de entrenamiento de armas de fuego (simulador)	Pieza
9733	55100043	Sistema de inspeccion por rayos "x"	Pieza
9734	55100044	Sistema laser para pistola (eq. O inst. Belico)	Pieza
9735	55100045	Sub-ametralladora (eq. O inst. Belico)	Pieza
9736	55100046	Tren posterior carro municion (eq. O inst. Belico)	Pieza
9737	55100047	Visor nocturno (eq. O inst. Belico)	Pieza
9738	55100060	Sistema de control de tiro garfio	Pieza
9739	55102	Equipo de seguridad publica y nacional	
9740	55100048	Equipo de seguridad publica y nacional	Pieza
9741	55100049	Equipo de inspeccion por rayos gamma	Pieza
9742	55100050	Remolque con equipo de rayos X	Pieza
9743	55100051	Poligrafo	Pieza
9744	55100052	Sistema de vision de lago alcance	Pieza
9745	55100053	Localizador GPS	Pieza
9746	5600	Maquinaria, otros equipos y herramientas	
9747	5610	Maquinaria y equipo agropecuario	
9748	56101	Maquinaria y equipo agropecuario	
9749	56100001	Apiario (maq. agricola)	Pieza
9750	56100002	Arado (maq. agricola)	Pieza
9751	56100003	Aspersor agricola de abonos (maq. agricola)	Pieza
9752	56100004	Bebedero (maq. agricola)	Pieza
9753	56100005	Beneficiadora de granos (sistema movil)	Pieza
9754	56100006	Bicicleta para trepar arboles (baumvelo) (maq. agricola)	Pieza
9755	56100007	Cargador de caña (maq. agricola)	Pieza
9756	56100008	Clasificadora algodon (maq. agricola)	Pieza
9757	56100009	Comedero (maq. agricola)	Pieza
9758	56100010	Cortadora caña (maq. agricola)	Pieza
9759	56100011	Cortarraices (maq. agricola)	Pieza
9760	56100012	Cosechadora (maq. agricola)	Pieza
9761	56100013	Criadero (maq. agricola)	Pieza
9762	56100014	Cultivadora (maq. agricola)	Pieza
9763	56100015	Desgranadora-trilladora-ensiladora (maq. agricola)	Pieza
9764	56100016	Desmanchadora y separadora de granos (maq. agricola)	Pieza
9765	56100017	Desmontadora (maq. agricola)	Pieza
9766	56100018	Dezasolvadora (maq. agricola)	Pieza
9767	56100019	Emasculador (maq. agricola)	Pieza
9768	56100020	Equipo riego (maq. agricola)	Pieza
9769	56100021	Escarificador (maq. agricola)	Pieza
9770	56100022	Escrepa (maq. agricola)	Pieza
9771	56100023	Extractor miel (maq. agricola)	Pieza
9772	56100024	Eyaculador electronico (maq. agricola)	Pieza
9773	56100025	Fertilizador (maq. agricola)	Pieza
9774	56100026	Fitotomo (maq. agricola)	Pieza
9775	56100027	Fumigador (maq. agricola)	Pieza
9776	56100028	Horquilla (maq. agricola)	Pieza
9777	56100029	Incubadora (maq. agricola)	Pieza
9778	56100030	Lanametro (medicion muestra de lana) (instrumento cientifico)	Pieza
9779	56100031	Laza trompas agropecuario (maq. agricola)	Pieza
9780	56100032	Manga y embarcadero para corral (maq. agricola)	Pieza
9781	56100033	Mesa pichonera (maq. Avicola)	Pieza
9782	56100034	Muestreador suelos (maq. Avicola)	Pieza
9783	56100035	Ordeñadora (maq. Avicola)	Pieza
9784	56100036	Paridero (maq. Avicola)	Pieza
9785	56100037	Pinza descolmilladora (maq. Avicola)	Pieza
9786	56100038	Pinza despesuñadora (maq. Avicola)	Pieza
9787	56300122	Silos para concreto	Pieza
9788	56100039	Pinza muescadora (maq. Avicola)	Pieza
9789	56100040	Pistola desparasitadora (interna y externa) (maq. Avicola)	Pieza
9790	56100041	Pistola implantes agropecuario (maq. Avicola)	Pieza
9791	56100042	Podador (maq. Avicola)	Pieza
9792	56100043	Prensadora forraje (maq. Avicola)	Pieza
9793	56100044	Pujavante (maq. Avicola)	Pieza
9794	56100045	Rastra (maq. Avicola)	Pieza
9795	56100046	Rastradiscos (maq. Avicola)	Pieza
9796	56100047	Roturador (maq. Avicola)	Pieza
9797	56100048	Sacrificadora de ganado (maq. Avicola)	Pieza
9798	56100049	Segadora (maq. Avicola)	Pieza
9799	56100050	Sembradora (maq. Avicola)	Pieza
9800	56100051	Surcadora (maq. Avicola)	Pieza
9801	56100052	Tatuador (maq. Avicola)	Pieza
9802	56100053	Termo porta semen (fijo o portatil) (maq. Avicola)	Pieza
9803	56100054	Tractor (maq. Avicola)	Pieza
9804	56100055	Trampa (maq. Avicola)	Pieza
9805	56100056	Trapiche (maq. Avicola)	Pieza
9806	56100057	Trasquiladora (esquiladora) (maq. Avicola)	Pieza
9807	56100058	Tren escrepas (maq. Avicola)	Pieza
9808	56100059	Trilladora, desgranadora y ensiladora (maq. Avicola)	Pieza
9809	56100060	Sistema fotovoltaico agropecuario	Pieza
9810	5620	Maquinaria y equipo industrial	
9811	56201	Maquinaria y equipo industrial	
9812	56200001	Achaflanadora (maq)	Pieza
9813	56200002	Activador automatizar valvulas	Pieza
9814	56200003	Afiladora industria (para madera, metal, plastico)	Pieza
9815	56200004	Aglomeradora	Pieza
9816	56200005	Alimentadora industrial	Pieza
9817	56200006	Alto horno	Pieza
9818	56200007	Amasadora	Pieza
9819	56200008	Anillos de carga digitalizados para analisis de suelos (instrumento cientifico)	Pieza
9820	56200009	Aparato  de baño de agua caliente con controlador de temperatura	Pieza
9821	56200010	Aparato controlador y monitoreador de temperatura mediante termopar   (instrumento cientifico)	Pieza
9822	56200011	Aparato de blindaje de plomo para detector de germanio (disminuye la radiacion gamma) (instrumento cientifico)	Pieza
9823	56200012	Aparato de despliegue de datos para lectura de medidores (instrumento cientifico)	Pieza
9824	56200013	Aparato electrico cortar y planchar cuellos	Pieza
9825	56200014	Aparato limpiador ultrasonico (limpia material para laboratorio por ondas ultrasonicas)	Pieza
9826	56200015	Aparato para baño isotermico  (instrumento cientifico)	Pieza
9827	56200016	Aparato para medir ph de soluciones (ph metro) (instrumento cientifico)	Pieza
9828	56200017	Aparato para mezclar y diluir gases	Pieza
9829	56200018	Aparato para reacciones cataliticas heterogeneas de hidrotratamientos (reactor)	Pieza
9830	56200019	Aparato para tratamiento termico (baño de sales)	Pieza
9831	56200020	Arco porta lanzas-malacate	Pieza
9832	56200021	Ariete hidraulico	Pieza
9833	56200022	Aspiradora industrial	Pieza
9834	56200023	Astilladora	Pieza
9835	56200024	Autoclave vertical (eq. De com., cinemat. O fotograf.)	Pieza
9836	56200025	Bambilete tambor	Pieza
9837	56200026	Banco automatico de capacitores (optimiza energia) (eq. Electrico)	Pieza
9838	56200027	Barredora vacio	Pieza
9839	56200028	Barrenadora (para madera, metal, piedra  y plastico)	Pieza
9840	56200030	Bastilladora	Pieza
9841	56200031	Bazooka (aspiracion grano)	Pieza
9842	56200032	Biseladora	Pieza
9843	56200033	Boceladora	Pieza
9844	56200034	Bomba accion directa (equipo)	Pieza
9845	56200035	Bomba alabe (equipo)	Pieza
9846	56200036	Bomba bloque vaiven (equipo)	Pieza
9847	56200037	Bomba centrifuga (equipo)	Pieza
9848	56200038	Bomba diafragma (equipo)	Pieza
9849	56200039	Bomba difusor (equipo)	Pieza
9850	56200040	Bomba embolo (equipo)	Pieza
9851	56200041	Bomba flujo axial impulsor (equipo)	Pieza
9852	56200042	Bomba flujo mixto (equipo)	Pieza
9853	56200043	Bomba helice (equipo)	Pieza
9854	56200044	Bomba hidraulica (equipo)	Pieza
9855	56200045	Bomba leva y piston (equipo)	Pieza
9856	56200046	Bomba lobulo (equipo)	Pieza
9857	56200047	Bomba neumatica (equipo)	Pieza
9858	56200048	Bomba potencia (equipo)	Pieza
9859	56200049	Bomba reciprocantes (equipo)	Pieza
9860	56200050	Bomba reloj (equipo)	Pieza
9861	56200051	Bomba rotativa (equipo)	Pieza
9862	56200052	Bomba rotatoria piston (equipo)	Pieza
9863	56200053	Bomba sumergible (equipo)	Pieza
9864	56200054	Bomba tornillo (equipo)	Pieza
9865	56200055	Bomba turbina generativa (equipo)	Pieza
9866	56200056	Bomba turbina vertical (equipo)	Pieza
9867	56200057	Bomba turbo (equipo)	Pieza
9868	56200058	Bomba vacio (equipo)	Pieza
9869	56200059	Bomba voluta (equipo)	Pieza
9870	56200060	Bordadora	Pieza
9871	56200061	Bordeadora	Pieza
9872	56200062	Brochador textiles	Pieza
9873	56200063	Bruzadora	Pieza
9874	56200064	Cabeceador para uso industrial	Pieza
9875	56200065	Cabeza para uso industrial	Pieza
9876	56200066	Cabezal para uso industrial	Pieza
9877	56200067	Cabria	Pieza
9878	56200068	Caja contenedor (movil)  (herramienta	Pieza
9879	56200069	Caja velocidades completa	Pieza
9880	56200070	Caldera con prensa para fundir cera (maq. Avicola)	Pieza
9881	56200071	Caldera de tubos de humo de calefaccion	Pieza
9882	56200072	Calderas de tubos de agua de calefaccion	Pieza
9883	56200075	Calderas de tubos de agua de potencia	Pieza
9884	56200076	Calderas de tubos de humo de calefaccion	Pieza
9885	56200077	Calderas de tubos de humo de potencia	Pieza
9886	56200079	Calderas de vapor	Pieza
9887	56200080	Calefactores de aire	Pieza
9888	56200081	Calentador vapor (considera caldera)	Pieza
9889	56200082	Camara combustion para quemador	Pieza
9890	56200083	Cardadora	Pieza
9891	56200084	Carro escuadra	Pieza
9892	56200085	Centrifugadora	Pieza
9893	56200086	Centro de maquinado de cnc (para practicas) (instrumento cientifico)	Pieza
9894	56200087	Centro de torneado cnc	Pieza
9895	56200088	Cerradora codos	Pieza
9896	56200089	Chumacera	Pieza
9897	56200090	Ciclon (maq. Avicola)	Pieza
9898	56200091	Cilindro gas (rellenable)	Pieza
9899	56200092	Cilindro termico	Pieza
9900	56200093	Colector	Pieza
9901	56200094	Colocadora bandas	Pieza
9902	56200095	Columna fraccionadora	Pieza
9903	56200096	Compactadora de basura	Pieza
9904	56200097	Compaginadora	Pieza
9905	56200098	Compiladora y emparejadora	Pieza
9906	56200099	Compresora (para usos industriales)	Pieza
9907	56200100	Compuerta	Pieza
9908	56200101	Contenedor de solventes utilizados en la elaboracion de marbetes (rotulos)	Pieza
9909	56200102	Contorneadora	Pieza
9910	56200103	Controlador de flujo masico para gases	Pieza
9911	56200104	Controlador de temperatura (controla temperatura al conectarle un termopar)	Pieza
9912	56200105	Controlador logico programable (instrumento cientifico)	Pieza
9913	56200106	Copiadora	Pieza
9914	56200107	Cortadora formas continuas	Pieza
9915	56200108	Cortadora lamina	Pieza
9916	56200109	Cortadora tela	Pieza
9917	56200110	Cosedora sacos	Pieza
9918	56200111	Cosedora tela industrial	Pieza
9919	56200112	Crakinadora	Pieza
9920	56200113	Cribadora	Pieza
9921	56200114	Crisol	Pieza
9922	56200115	Cuarteadora	Pieza
9923	56200116	Curvadora	Pieza
9924	56200117	De compresion (maquina)	Pieza
9925	56200118	De tiempo fraguado (maquina)	Pieza
9926	56200119	Desaladora (maquina)	Pieza
9927	56200120	Desbastador mosaicos	Pieza
9928	56200121	Desborradora	Pieza
9929	56200122	Descargador camiones	Pieza
9930	56200123	Descascadora (maquina)	Pieza
9931	56200124	Descremadora	Pieza
9932	56200125	Desfibradora	Pieza
9933	56200126	Desgasificadora lodos	Pieza
9934	56200127	Deshebradora ropa	Pieza
9935	56200128	Deshidratadora	Pieza
9936	56200129	Deshornadora planta de coquizacion	Pieza
9937	56200130	Desmenuzadora	Pieza
9938	56200131	Desmineralizadora para uso industrial	Pieza
9939	56200132	Desorilladora	Pieza
9940	56200133	Despepitadora	Pieza
9941	56200134	Despulpadora	Pieza
9942	56200135	Destiladora	Pieza
9943	56200136	Desvaporadora	Pieza
9944	56200137	Determinador reactividad coque (instrumento cientifico)	Pieza
9945	56200138	Devanadora	Pieza
9946	56200139	Diferencial completo	Pieza
9947	56200140	Difusor	Pieza
9948	56200141	Dobladora-insertora	Pieza
9949	56200142	Dobladoras (para madera, metal, plastico, papel y tubo)	Pieza
9950	56200143	Ductiladora	Pieza
9951	56200144	Electrostatica (maquina)	Pieza
9952	56200145	Elevador de cangilones	Pieza
9953	56200146	Elevadores (carga)	Pieza
9954	56200147	Elevadores (personal)	Pieza
9955	56200148	Embaladora	Pieza
9956	56200149	Embobinadora	Pieza
9957	56200150	Embolsadora	Pieza
9958	56200151	Embotelladora	Pieza
9959	56200152	Empacadora	Pieza
9960	56200153	Enchapadora	Pieza
9961	56200154	Enderezadora	Pieza
9962	56200155	Enderezadora (para madera, metal, plastico)	Pieza
9963	56200156	Endulzadora	Pieza
9964	56200157	Endurecedora cristal	Pieza
9965	56200158	Engargoladora industrial (para madera, metal, plastico)	Pieza
9966	56200159	Engrapadora industrial	Pieza
9967	56200160	Envasadora	Pieza
9968	56200161	Equipo caracterizador de materiales por absorcion de gas (equipo nova 1200)	Pieza
9969	56200162	Equipo cernido (harina)	Pieza
9970	56200163	Equipo circulador agua	Pieza
9971	56200164	Equipo control de pozos	Pieza
9972	56200165	Equipo controlador de baja temperatura (instrumento cientifico)	Pieza
9973	56200166	Equipo de degradacion a baja temperatura (aparato cientifico)	Pieza
9974	56200167	Equipo de perforacion para analisis de suelos (instrumento cientifico)	Pieza
9975	56200168	Equipo de prepensa digital	Pieza
9976	56200169	Equipo de pruebas de voltametria o analisis de impedancia electroquimica (instrumento cientifico)	Pieza
9977	56200170	Equipo de reducibilidad baja carga (aparato cientifico)	Pieza
9978	56200171	Equipo de reducibilidad estatica (aparato cientifico)	Pieza
9979	56200172	Equipo de reparacion y terminacion de pozos	Pieza
9980	56200173	Equipo de vulcanizacion	Pieza
9981	56200174	Equipo decantacion, flotacion y lixiviacion de minerales	Pieza
9982	56200175	Equipo electronico inspeccion de tuberia	Pieza
9983	56200176	Equipo electronico obtencion cortes pozos	Pieza
9984	56200177	Equipo extraccion lirio	Pieza
9985	56200178	Equipo extractor y/o cortador de cilindros de muestras para analisis de suelos (instrumento cientifico)	Pieza
9986	56200179	Equipo hidroneumatico	Pieza
9987	56200180	Equipo medicion de pozos	Pieza
9988	56200181	Equipo para aire acondicionado	Pieza
9989	56200182	Equipo para el control de la contaminacion	Pieza
9990	56200183	Equipo para lubricacion industrial	Pieza
9991	56200184	Equipo para obtencion de muestras por enfriamiento (melt spinner) (instrumento cientifico)	Pieza
9992	56200185	Equipo para soldar	Pieza
9993	56200186	Equipo preparador de laminas de impresion	Pieza
9994	56200187	Equipo secador de polvos en suspension	Pieza
9995	56200188	Equipo sondeo	Pieza
9996	56200189	Equipo tratamiento aguas	Pieza
9997	56200190	Equipos de vulcanizacion	Pieza
9998	56200191	Escuadradora	Pieza
9999	56200192	Esferica (maquina)	Pieza
10000	56200193	Esmaltadora y envoltura de tubo	Pieza
10001	56200194	Espolvoreadora	Pieza
10002	56200195	Estampadora	Pieza
10003	56200196	Estranguladora y retenedora	Pieza
10004	56200197	Estruders	Pieza
10005	56200198	Estufa fundidor	Pieza
10006	56200199	Estufas	Pieza
10007	56200200	Evaporadora	Pieza
10008	56200201	Exauster transportador (eq. Para comercios)	Pieza
10009	56200202	Exprimidora	Pieza
10010	56200203	Extractor de aire	Pieza
10011	56200204	Extractor polvo	Pieza
10012	56200205	Fermentadora	Pieza
10013	56200206	Filtro industrial	Pieza
10014	56200207	Filtros y purificadores de agua	Pieza
10015	56200208	Filtros y purificadores de aire	Pieza
10016	56200209	Forradora botones	Pieza
10017	56200210	Fraccionadora gabinetes de alarma	Pieza
10018	56200211	Fragua-forja	Pieza
10019	56200212	Fundidor tipo para imprenta	Pieza
10020	56200213	Garrucha	Pieza
10021	56200214	Gausometro (aparato para medir la induccion del campo magnetico) (instrumento cientifico)	Pieza
10022	56200215	Generador calor con ventilador	Pieza
10023	56200216	Generador corriente energia nuclear	Pieza
10024	56200217	Generador vapor (considera caldera)	Pieza
10025	56200218	Grua viajera	Pieza
10026	56200219	Guia planta de coquizacion	Pieza
10027	56200220	Guillotina industrial	Pieza
10028	56200221	Hiladora	Pieza
10029	56200222	Horno o plancha para serigrafia (secado)	Pieza
10030	56200223	Horno tubular con control de temperatura	Pieza
10031	56200224	Hornos de acero	Pieza
10032	56200225	Hornos de induccion	Pieza
10033	56200226	Hornos estaticos	Pieza
10034	56200227	Hornos para vulcanizar balatas	Pieza
10035	56200228	Hornos rotatorios	Pieza
10036	56200229	Impacto (maquina de)	Pieza
10037	56200230	Impregnadora chapa	Pieza
10038	56200231	Impresora alta velocidad	Pieza
10039	56200232	Impresora de seis cabezas	Pieza
10040	56200233	Incinerador	Pieza
10041	56200234	Insertadora	Pieza
10042	56200235	Insoladora serigrafica (herramienta	Pieza
10043	56200236	Intercambiadores de calor	Pieza
10044	56200237	Inyector industrial	Pieza
10045	56200238	Inyectora	Pieza
10046	56200239	Laminadora	Pieza
10047	56200240	Lanzacabos	Pieza
10048	56200241	Lapidadora	Pieza
10049	56200242	Lavadora de autos	Pieza
10050	56200243	Lavadora industrial	Pieza
10051	56200244	Licuadora industrial banda	Pieza
10052	56200245	Lijadora industrial	Pieza
10053	56200246	Limpiadora	Pieza
10054	56200247	Listonadora	Pieza
10055	56200248	Maniful	Pieza
10056	56200249	Maquina de coser industrial	Pieza
10057	56200250	Maquina de grabado ciega y grabado a color	Pieza
10058	56200251	Maquina de plastificacion de documentos y tarjetas inteligentes	Pieza
10059	56200252	Maquina granuladora	Pieza
10060	56200253	Maquina para agitar o mezclar soluciones en un medio acuoso (agitador electrico)	Pieza
10061	56200254	Maquina procesadora hule natural	Pieza
10062	56200255	Maquina restauradora de papel	Pieza
10063	56200256	Marcadora ropa	Pieza
10064	56200257	Marco exposicion multilith	Pieza
10065	56200258	Marmitas (caldera)	Pieza
10066	56200259	Martinete industrial	Pieza
10067	56200260	Matizadora imprenta	Pieza
10068	56200261	Medidor controlador para sensores de vacio (instrumento cientifico)	Pieza
10069	56200262	Medidor de presion de material fundido en el dado de extrusion (traductor de presion) (instrumento cientifico)	Pieza
10070	56200263	Medidora superficie de pieles	Pieza
10071	56200264	Mesa de gravedad	Pieza
10072	56200265	Mesa rotatoria octagonal (para practicas) (instrumento cientifico)	Pieza
10073	56200266	Metalizadora	Pieza
10074	56200267	Mezcladora-batidora industrial	Pieza
10075	56200268	Minero continuo (maquina>	Pieza
10076	56200269	Molde industrial	Pieza
10077	56200270	Moldeadora	Pieza
10078	56200271	Molduladora	Pieza
10079	56200272	Molino industrial	Pieza
10080	56200273	Molino para carne	Pieza
10081	56200274	Molino para granos; semillas y productos vegetales	Pieza
10082	56200275	Molino para minerales	Pieza
10083	56200276	Motoestibador o montacarga industrial	Pieza
10084	56200277	Motogenerador corriente	Pieza
10085	56200278	Motor diesel	Pieza
10086	56200279	Motor electrico	Pieza
10087	56200280	Motor fuera de borda	Pieza
10088	56200281	Motor gas	Pieza
10089	56200282	Motor gasolina	Pieza
10090	56200283	Motor hidraulico	Pieza
10091	56200284	Motor neumatico	Pieza
10092	56200285	Motor tractolina	Pieza
10093	56200286	Motor vapor	Pieza
10094	56200287	Motores de viento	Pieza
10095	56200288	Motorreductor	Pieza
10096	56200289	Muestreador aguas materiales	Pieza
10097	56200290	Muestreador sedimento	Pieza
10098	56200291	Mufla (caldera)	Pieza
10099	56200292	Nanovoltimetro / ohmetro (instrumento cientifico)	Pieza
10100	56200293	Nibladora universal	Pieza
10101	56200294	Niveladora arrastre	Pieza
10102	56200295	Niveladora de bielas	Pieza
10103	56200296	Ojaladora	Pieza
10104	56200297	Overlock (maquina)	Pieza
10105	56200298	Pantografo tridimensional	Pieza
10106	56200299	Parchadora chapa	Pieza
10107	56200300	Parquetera	Pieza
10108	56200301	Pegadora  botones	Pieza
10109	56200302	Peletizadora	Pieza
10110	56200303	Perforadora electrica papel	Pieza
10111	56200304	Pescante	Pieza
10112	56200305	Planchadora mangas	Pieza
10113	56200306	Planchadora puños y cuello	Pieza
10114	56200307	Planchadora rodillos	Pieza
10115	56200308	Planchadora vapor	Pieza
10116	56200309	Plantas de proceso para aromaticos superiores	Pieza
10117	56200310	Plantas de proceso para benceno	Pieza
10118	56200311	Plantas de proceso para breas	Pieza
10119	56200312	Plantas de proceso para butadienos	Pieza
10120	56200313	Plantas de proceso para butilenos	Pieza
10121	56200314	Plantas de proceso para etilenos	Pieza
10122	56200315	Plantas de proceso para hidrogeno	Pieza
10123	56200316	Plantas de proceso para naftalenos	Pieza
10124	56200317	Plantas de proceso para nitrogeno	Pieza
10125	56200318	Plantas de proceso para oxido de carbono	Pieza
10126	56200319	Plantas de proceso para propilenos	Pieza
10127	56200320	Plantas de proceso para toluenos	Pieza
10128	56200321	Plantas de proceso para xilenos	Pieza
10129	56200322	Plantas de procesos petroquimicos	Pieza
10130	56200323	Plantas generadoras de corriente alterna (energia nuclear)	Pieza
10131	56200324	Plantas generadoras de corriente alterna est. De gasolina	Pieza
10132	56200325	Plantas generadoras de corriente alterna estacionarias de diesel	Pieza
10133	56200326	Plantas generadoras de corriente alterna estacionarias de gas	Pieza
10134	56200327	Plantas generadoras de corriente alterna moviles de diesel	Pieza
10135	56200328	Plantas generadoras de corriente alterna moviles de gas	Pieza
10136	56200329	Plantas generadoras de corriente alterna moviles de gasolina	Pieza
10137	56200330	Plantas generadoras de corriente continua moviles de diesel	Pieza
10138	56200331	Plantas generadoras de corriente continua moviles de gas	Pieza
10139	56200332	Plantas generadoras de corriente continua moviles de gasolina	Pieza
10140	56200333	Plantas generadoras de corriente estacionaria de diesel	Pieza
10141	56200334	Plantas generadoras de corriente estacionaria de gas	Pieza
10142	56200335	Plantas generadoras de corriente estacionaria de gasolina	Pieza
10143	56200336	Plantas para industria de la alimentacion, bebidas y tabacos	Pieza
10144	56200337	Plantas para industria del cuero y piel	Pieza
10145	56200338	Plantas para industria del transporte	Pieza
10146	56200339	Plantas para industria maderera	Pieza
10147	56200340	Plantas para industria minera	Pieza
10148	56200341	Plantas para industria petrolera	Pieza
10149	56200342	Plantas para industria quimica (petroquimica excluida)	Pieza
10150	56200343	Plantas para industria siderurgia	Pieza
10151	56200344	Plantas para industria textil	Pieza
10152	56200345	Plantas para industrias del papel y hule	Pieza
10153	56200346	Plataforma (patron)	Pieza
10154	56200347	Polipasto	Pieza
10155	56200348	Precalentadores de aire	Pieza
10156	56200349	Prensa (para madera, metal, piedra y plastico)	Pieza
10157	56200350	Prensa encuadernacion	Pieza
10158	56200351	Prensadora cadena	Pieza
10159	56200352	Prensadora contacto	Pieza
10160	56200353	Prensadora encuadernacion	Pieza
10161	56200354	Prensadora giratoria graduada	Pieza
10162	56200355	Prensadora hidraulica	Pieza
10163	56200356	Prensadora laboratorio	Pieza
10164	56200357	Prensadora montaje con calor	Pieza
10165	56200358	Prensadora tubo	Pieza
10166	56200359	Preventor perforacion	Pieza
10167	56200360	Probador hidraulico para tuberia	Pieza
10168	56200361	Procesadora fibras	Pieza
10169	56200362	Procesadora petroquimica	Pieza
10170	56200363	Procesadora quimica	Pieza
10171	56200364	Productora cubitos y bloques de hielo	Pieza
10172	56200365	Productora discos de lamina	Pieza
10173	56200366	Productora sinter	Pieza
10174	56200367	Puerta boveda combinacion	Pieza
10175	56200368	Pulidora (para madera, metal, piedra y plastico)	Pieza
10176	56200369	Pulverizadora	Pieza
10177	56200370	Punteadora industrial	Pieza
10178	56200371	Purificador industrial agua	Pieza
10179	56200372	Quemador diesel	Pieza
10180	56200373	Quemador electrico	Pieza
10181	56200374	Quemador gas	Pieza
10182	56200375	Quemador petroleo	Pieza
10183	56200376	Reacondicionador tambores	Pieza
10184	56200377	Recalentadores	Pieza
10185	56200378	Recicladora ecologica	Pieza
10186	56200379	Rectificador bielas	Pieza
10187	56200380	Rectificador cigüeñales	Pieza
10188	56200381	Rectificador cilindros	Pieza
10189	56200382	Rectificador flechas	Pieza
10190	56200383	Rectificador superficies planas	Pieza
10191	56200384	Rectificador valvulas	Pieza
10192	56200385	Rectificadora de volantes y bases de clutch	Pieza
10193	56200386	Rectificadoras (madera, metal, piedra y plastico)	Pieza
10194	56200387	Reductor e incrementadores de velocidad	Pieza
10195	56200388	Refrigeradores industriales	Pieza
10196	56200392	Roladora (madera, metal, plastico)	Pieza
10197	56200393	Rompedora industrial	Pieza
10198	56200394	Rosca distribucion	Pieza
10199	56200395	Roscadora (madera, metal y plastico)	Pieza
10200	56200396	Rotomartillo (instrumento cientifico)	Pieza
10201	56200397	Secadora	Pieza
10202	56200398	Seleccionadora	Pieza
10203	56200399	Selladora	Pieza
10204	56200400	Separador de arena (bomba sumergible o de turbina) (equipo)	Pieza
10205	56200401	Separadora gas	Pieza
10206	56200402	Silo	Pieza
10207	56200403	Sistema de control automatico de enfriamiento en hidraulica (instrumento cientifico)	Pieza
10208	56200404	Sistema de entrenamiento de tiempos y movimientos (para practicas) (instrumento cientifico)	Pieza
10209	56200405	Sobrehiladora	Pieza
10210	56200406	Soldadora a tope para sierra cinta (eq. Electrico)	Pieza
10211	56200407	Sombrilla para uso industrial	Pieza
10212	56200408	Sonda subsuelo	Pieza
10213	56200409	Sopladora industrial	Pieza
10214	56200410	Tablero control sistema combustion	Pieza
10215	56200411	Tableros manometros	Pieza
10216	56200412	Taladro (para madera, metal, piedra y plastico)	Pieza
10217	56200413	Tamices (juego de ) para separar sedimentos marinos (aparato cientifico)	Pieza
10218	56200414	Tamizador	Pieza
10219	56200415	Tanque almacenamiento para combustibles y lubricantes	Pieza
10220	56200416	Tanque alta presion	Pieza
10221	56200417	Tanque enfriamiento	Pieza
10222	56200418	Tanque fertilizador	Pieza
10223	56200419	Tanque presion y vacio	Pieza
10224	56200420	Tanque reactor (vidriado y/o acero inoxidable)	Pieza
10225	56200421	Tanques de almacenamiento de hule	Pieza
10226	56200422	Tejedora industrial	Pieza
10227	56200423	Telar manual y electrico	Pieza
10228	56200424	Tendedora tela	Pieza
10229	56200425	Tensionadora	Pieza
10230	56200426	Termo higrometro de baja precision (medidor de temperaturas y humedad) (instrumento cientifico)	Pieza
10231	56200427	Termo higrometro de precision (medidor de temperaturas y humedad) (instrumento cientifico)	Pieza
10232	56200428	Termocople (medidor de temperatura del material fundido en el dado de extrusion) (instrumento cientifico)	Pieza
10233	56200429	Termometro infrarrojo (mide temperaturas por señal infrarroja) (instrumento cientifico)	Pieza
10234	56200430	Tina para fundir cera (maq. Avicola)	Pieza
10235	56200431	Tornilladora	Pieza
10236	56200432	Torno (para madera, metal, piedra y plastico	Pieza
10237	56200433	Torre enfriamiento	Pieza
10238	56200434	Torre maquina perforadora	Pieza
10239	56200435	Torre movil	Pieza
10240	56200436	Torre quemador	Pieza
10241	56200437	Tortilladora automatica	Pieza
10242	56200438	Tostador granos	Pieza
10243	56200439	Tractor industrial	Pieza
10244	56200440	Trampa de nitrogeno liquido (condensa gases)	Pieza
10245	56200441	Trampa vapor	Pieza
10246	56200442	Transportador helicoidal	Pieza
10247	56200443	Transportador vibratorio	Pieza
10248	56200444	Transportadora de cadena y cadenas transportadoras	Pieza
10249	56200445	Transportadoras de bandas	Pieza
10250	56200446	Transportadores de rodillo	Pieza
10251	56200447	Tratadora	Pieza
10252	56200448	Tratadora de granos	Pieza
10253	56200449	Trefiladora (para madera, metal, piedra y plastico)	Pieza
10254	56200450	Tren laminacion	Pieza
10255	56200451	Trituradora industrial	Pieza
10256	56200452	Trompa vacio	Pieza
10257	56200453	Tronzadora (sierra de troceo para madera, metal y plastico)	Pieza
10258	56200454	Turbinas	Pieza
10259	56200455	Turbo generador	Pieza
10260	56200456	Unidad condensadora	Pieza
10261	56200457	Unidad enfriadora de liquidos para aire acondicionado	Pieza
10262	56200458	Universal para compresion y tension (maquina	Pieza
10263	56200459	Ventilador fragua	Pieza
10264	56200460	Ventiladores axiales en arillos	Pieza
10265	56200461	Ventiladores axiales en ductos	Pieza
10266	56200462	Ventiladores centrifugos de aspa adelantada	Pieza
10267	56200463	Ventiladores centrifugos de aspas atrasadas	Pieza
10268	56200464	Ventiladores centrifugos de aspas planas	Pieza
10269	56200465	Ventiladores turboaxiales	Pieza
10270	56200466	Verificador de calidad de impresion de marbetes (rotulos), incluye monitor	Pieza
10271	56200467	Vibrador para calado de lodos	Pieza
10272	56200468	Voltimetro para medir electretos (instrumento cientifico)	Pieza
10273	56200469	Pasteurizadora de leche (esterilizadora)	Pieza
10274	56200470	Sacabocados hidraulico	Pieza
10275	56200471	Hidrolavadora de alta presion	Pieza
10276	56200472	Sistema de control de flama	Pieza
10277	56200473	Electroerocionadora	Pieza
10278	56200474	Maquina litografica	Pieza
10279	56200475	Purificadores para aceite y combustible	Pieza
10280	56200476	Sistema de arranque	Pieza
10281	56200477	Juego industrial combinado	Pieza
10282	56200478	Desmontador	Pieza
10283	56200479	Olla para chorro de arena (Sand Blast)	Pieza
10284	56200480	Bomba despachadora de combustible	Pieza
10285	56200481	Linea para tratamientos superficiales	Pieza
10286	56200482	Banco de pruebas del mecanismo de retardo	Pieza
10287	56200483	Equipo de impresion, codificadora y marcaje industrial	Pieza
10288	56200484	Aserradero con motor	Pieza
10289	5630	Maquinaria y equipo de construccion	
10290	56301	Maquinaria y equipo de construccion	
10291	56300001	Acabadora-allanadora	Pieza
10292	56300002	Achafladora	Pieza
10293	56300003	Adaptador desconectador mole-drill	Pieza
10294	56300004	Aditamento arado para subsuelo	Pieza
10295	56300005	Aditamento excavadora	Pieza
10296	56300006	Afinadoras de taludes	Pieza
10297	56300007	Alimentadora de agregados	Pieza
10298	56300008	Andamio	Pieza
10299	56300009	Aparato gps para medir distancias geodesicas (aparato cientifico)	Pieza
10300	56300010	Apisonadora	Pieza
10301	56300011	Apisonadora neumatica	Pieza
10302	56300012	Aplanadora compactacion	Pieza
10303	56300013	Arado nieve	Pieza
10304	56300014	Ataludadora	Pieza
10305	56300015	Bacheadora	Pieza
10306	56300016	Barra perforacion	Pieza
10307	56300017	Barrenadoras (construccion)	Pieza
10308	56300018	Barril perforacion	Pieza
10309	56300020	Base compresora	Pieza
10310	56300021	Bloquera (blocks concreto)	Pieza
10311	56300022	Boquilla dragado	Pieza
10312	56300023	Brazo hidraulico (perforadora)	Pieza
10313	56300024	Briqueteador	Pieza
10314	56300025	Cabeza golpeadora perforacion	Pieza
10315	56300026	Cabeza golpeo para tubo ademe	Pieza
10316	56300027	Cabezote barra de perforacion	Pieza
10317	56300028	Cabrestante arrastre (neumatico o electrico)	Pieza
10318	56300029	Calentador aceite	Pieza
10319	56300030	Cargador frontal	Pieza
10320	56300031	Cavadora	Pieza
10321	56300032	Compactador placa vibratoria	Pieza
10322	56300033	Compactadora traccion	Pieza
10323	56300034	Compresora (construccion)	Pieza
10324	56300035	Cortador varilla	Pieza
10325	56300036	Cortador varilla (instrumento cientifico)	Pieza
10326	56300037	Cortadora de concreto	Pieza
10327	56300038	Criba	Pieza
10328	56300039	Cuarteadora	Pieza
10329	56300040	Cubeta via-cable	Pieza
10330	56300041	Cucharon	Pieza
10331	56300042	Demoledora neumatica	Pieza
10332	56300043	Desarenadora	Pieza
10333	56300044	Desvaradora	Pieza
10334	56300045	Dobladora lamina	Pieza
10335	56300046	Dobladora universal varilla y solera	Pieza
10336	56300047	Dosificador	Pieza
10337	56300048	Draga excavacion	Pieza
10338	56300049	Enlucidadora caminos	Pieza
10339	56300050	Ensanchadora caminos	Pieza
10340	56300051	Entibadora neumatica	Pieza
10341	56300052	Equipo almacenamiento y suministro cemento	Pieza
10342	56300053	Equipos de nivelacion de suelos	Pieza
10343	56300054	Equipos para lodos	Pieza
10344	56300055	Escarificador hidraulico	Pieza
10345	56300056	Escrepas para carga	Pieza
10346	56300057	Escudo barrenacion	Pieza
10347	56300058	Esparcidor	Pieza
10348	56300059	Esparcidoras para petrolizado de concreto	Pieza
10349	56300060	Estacion total (aparato cientifico)	Pieza
10350	56300061	Excavadora neumatica	Pieza
10351	56300062	Excavadoras	Pieza
10352	56300063	Gavilan para construccion	Pieza
10353	56300064	Grua hidraulica	Pieza
10354	56300065	Guarnicionera	Pieza
10355	56300066	Guia mecanica	Pieza
10356	56300067	Hincadora tablaestaca	Pieza
10357	56300068	Hojas radiograficas para construccion	Pieza
10358	56300069	Horno pruebas asfalto	Pieza
10359	56300070	Inyector de concreto	Pieza
10360	56300071	Inyector de techado	Pieza
10361	56300072	Jumbo	Pieza
10362	56300073	Lanzadera concreto	Pieza
10363	56300074	Lavadora concreto	Pieza
10364	56300075	Levador varillas	Pieza
10365	56300076	Lijadora	Pieza
10366	56300077	Malacate	Pieza
10367	56300078	Maquina de colado continuo	Pieza
10368	56300079	Maquinas pintarrayas	Pieza
10369	56300080	Martillos para construccion	Pieza
10370	56300081	Martinete	Pieza
10371	56300082	Mezcladora de concreto	Pieza
10372	56300083	Molde (construccion)	Pieza
10373	56300084	Motobomba (autocebante)	Pieza
10374	56300085	Motoconformadora	Pieza
10375	56300086	Motoescrepa para carga	Pieza
10376	56300087	Motoperforadora	Pieza
10377	56300088	Niveladora (moto)	Pieza
10378	56300089	Nodriza petrolizadora de concreto	Pieza
10379	56300090	Pala hidraulica	Pieza
10380	56300095	Perforadora pesada automatica	Pieza
10381	56300096	Petrolificadoras	Pieza
10382	56300097	Piloteadora	Pieza
10383	56300098	Pinta raya	Pieza
10384	56300099	Pison para compactacion	Pieza
10385	56300100	Plantas de asfalto	Pieza
10386	56300101	Plantas de cribado	Pieza
10387	56300102	Plantas de trituracion	Pieza
10388	56300103	Plantas dosificadoras de concreto	Pieza
10389	56300104	Pluma elevacion-hidraulica	Pieza
10390	56300105	Portico de sustitucion	Pieza
10391	56300106	Prensadora compactacion estatica de suelos	Pieza
10392	56300107	Prisma rallador concreto	Pieza
10393	56300108	Pulidora construccion	Pieza
10394	56300109	Pulidora-lijadora	Pieza
10395	56300110	Punteadora	Pieza
10396	56300111	Quebradora	Pieza
10397	56300112	Ranuradora	Pieza
10398	56300113	Regladoras de piso	Pieza
10399	56300114	Retroexcavadora	Pieza
10400	56300115	Revolvedoras para mezcla de concreto	Pieza
10401	56300116	Rodillo apisonador	Pieza
10402	56300117	Rodillo compactacion	Pieza
10403	56300118	Roladora de riel	Pieza
10404	56300119	Rompedora para barrenacion	Pieza
10405	56300120	Rompedora pavimentos	Pieza
10406	56300121	Rotadora estabilizacion suelos	Pieza
10407	56300123	Sonda electrica pozo	Pieza
10408	56300124	Sopleteadora concreto	Pieza
10409	56300125	Tabiquera	Pieza
10410	56300126	Terminadora pavimento	Pieza
10411	56300131	Track drill (perforadora de carretilla montaje de oruga)	Pieza
10412	56300132	Tractor para construccion	Pieza
10413	56300133	Trailla transportador portatil	Pieza
10414	56300134	Trascabo	Pieza
10415	56300135	Unidad combinada (calentador de vapor, de petroleo y bombeo)	Pieza
10416	56300136	Unidad rotacion	Pieza
10417	56300137	Vibrador neumatico	Pieza
10418	56300138	Zanjadora-rellenadora	Pieza
10419	56300139	Base para deslizar tarima (tortuga)	Pieza
10420	56300140	Soporte para remolque (patin)	Pieza
10421	56300141	Unidad electro-hidraulica de transferencia	Pieza
10422	5640	Sistemas de aire acondicionado, calefaccion y de refrigeracion industrial y comercial	
10423	56401	Sistemas de aire acondicionado, calefaccion y de refrigeracion industrial y comercial	
10424	5650	Equipo de comunicacion y telecomunicacion	
10425	56501	Equipo y aparatos de comunicaciones y telecomunicaciones	
10426	56500001	Acelerometro (transductor de aceleracion) (eq. De com., cinemat. O fotograf.)	Pieza
10427	56500002	Acoplador (dispositivo que divide señal) (eq. De com., cinemat. O fotograf.)	Pieza
10428	56500003	Adaptador onda corta (eq. De com., cinemat. O fotograf.)	Pieza
10429	56500004	Aislador (dispositivo para atenuar señal) (eq. De com., cinemat. O fotograf.)	Pieza
10430	56500005	Amplificador (dispositivo que incrementa el nivel de señal) (eq. De reproduccion)	Pieza
10431	56500006	Amplificador de antena (eq. De reproduccion)	Pieza
10432	56500007	Amplificador de bajo ruido (satelital) (eq. De com., cinemat. O fotograf.)	Pieza
10433	56500008	Amplificador de frecuencia (eq. De reproduccion)	Pieza
10434	56500009	Amplificador de grabacion (eq. De reproduccion)	Pieza
10435	56500010	Amplificador de medida (eq. De reproduccion)	Pieza
10436	56500011	Amplificador de potencia (eq. De reproduccion)	Pieza
10437	56500012	Amplificador de sonido (eq. De com., cinemat. O fotograf.)	Pieza
10438	56500013	Amplificador de transconductancia (eq. De reproduccion)	Pieza
10439	56500014	Amplificador de trazo (eq. De reproduccion)	Pieza
10440	56500015	Amplificador distribuidor de audio (eq. De reproduccion)	Pieza
10441	56500016	Amplificador distribuidor de video (eq. De reproduccion)	Pieza
10442	56500017	Amplificador stereo (eq. De reproduccion)	Pieza
10443	56500018	Analizador de distorsion (eq. De com., cinemat. O fotograf.)	Pieza
10444	56500019	Analizador de espectros con demulador de audio (eq. De com., cinemat. O fotograf.)	Pieza
10445	56500020	Analizador de estados logicos (eq. De com., cinemat. O fotograf.)	Pieza
10446	56500021	Analizador de forma de onda (eq. De com., cinemat. O fotograf.)	Pieza
10447	56500022	Analizador de frecuencia (eq. De com., cinemat. O fotograf.)	Pieza
10448	56500023	Analizador de impedancia (eq. De com., cinemat. O fotograf.)	Pieza
10449	56500024	Analizador de modulacion (eq. De com., cinemat. O fotograf.)	Pieza
10450	56500025	Analizador de radiocomunicaciones (eq. De com., cinemat. O fotograf.)	Pieza
10451	56500026	Analizador de ruido  (eq. De com., cinemat. O fotograf.)	Pieza
10452	56500027	Analizador de señal (eq. De com., cinemat. O fotograf.)	Pieza
10453	56500028	Analizador de sistemas (eq. De com., cinemat. O fotograf.)	Pieza
10454	56500029	Analizador de vectores (eq. De com., cinemat. O fotograf.)	Pieza
10455	56500030	Analizador de video (eq. De com., cinemat. O fotograf.)	Pieza
10456	56500031	Antena (eq. De com., cinemat. O fotograf.)	Pieza
10457	56500032	Antena logaritmica (eq. De com., cinemat. O fotograf.)	Pieza
10458	56500033	Antena parabolica (eq. De com., cinemat. O fotograf.)	Pieza
10459	56500034	Anteojos con micro camara oculta con accesorios, microfonos y banco de baterias (eq. De com., cinemat. O fotograf.)	Pieza
10460	56500035	Aparato distribuidor y transformador de energia (eq. De com., cinemat. O fotograf.)	Pieza
10461	56500036	Aparato generador de señales de audio (eq. De com., cinemat. O fotograf.)	Pieza
10462	56500037	Aparato radiotelegrafico-telegrafo (eq. De com., cinemat. O fotograf.)	Pieza
10463	56500038	Aparato receptor de señal (inalambrico) (receiver) (eq. De com., cinemat. O fotograf.)	Pieza
10464	56500039	Aparato telefonico (eq. De reproduccion)	Pieza
10465	56500040	Aparato telefonico automovil (eq. De com., cinemat. O fotograf.)	Pieza
10466	56500041	Aparato videotape (eq. De com., cinemat. O fotograf.)	Pieza
10467	56500042	Apuntador electronico (eq. De com., cinemat. O fotograf.)	Pieza
10468	56500043	Base para camara de video con monitor controlador (eq. De com., cinemat. O fotograf.)	Pieza
10469	56500044	Base para carga de comunicacion del lector de codigo de barras (eq. De com., cinemat. O fotograf.)	Pieza
10470	56500045	Base para transductores del magnetometro (eq. De com., cinemat. O fotograf.)	Pieza
10471	56500046	Base transmisora telefonia (eq. De com., cinemat. O fotograf.)	Pieza
10472	56500047	Belinografo (facsimil y fototelegrafo) (eq. De com., cinemat. O fotograf.)	Pieza
10473	56500048	Cabeza de control movil spectra (eq. De com., cinemat. O fotograf.)	Pieza
10474	56500049	Cabeza rotatoria de antena (eq. De com., cinemat. O fotograf.)	Pieza
10475	56500050	Calibrador de rango (instrumento cientifico)	Pieza
10476	56500051	Calibrador de resistencias (instrumento cientifico)	Pieza
10477	56500052	Calibrador de voltaje (instrumento cientifico)	Pieza
10478	56500053	Calibrador medidor de potencia (instrumento cientifico)	Pieza
10479	56500054	Calibrador para acelerometro (instrumento cientifico)	Pieza
10480	56500055	Calibrador para vectorscopio (instrumento cientifico)	Pieza
10481	56500056	Camara t.v. (eq. De com., cinemat. O fotograf.)	Pieza
10482	56500057	Campana electrica (campana de aviso de falta de carga de baterias) (eq. Electrico)	Pieza
10483	62401033	Demolicion de taller	Obra
10484	56500058	Carga fantasma o artificial  (eq. De com., cinemat. O fotograf.)	Pieza
10485	56500059	Carga terminal de radio frecuencia (eq. De com., cinemat. O fotograf.)	Pieza
10486	56500060	Carro dolly camara t.v. (eq. De com., cinemat. O fotograf.)	Pieza
10487	56500061	Central electronica e.s.s. (eq. De com., cinemat. O fotograf.)	Pieza
10488	56500062	Central tipo telefono (eq. De com., cinemat. O fotograf.)	Pieza
10489	56500063	Circuito cerrado de television (eq. De com., cinemat. O fotograf.)	Pieza
10490	56500064	Conmutador de transferencia (conecta antenas y emite señal) (eq. de com., cinemat. o fotograf.)	Pieza
10491	56500065	Conmutador de video (eq. De com., cinemat. O fotograf.)	Pieza
10492	56500066	Conmutador manual (diadema) (eq. De com., cinemat. O fotograf.)	Pieza
10493	56500067	Conmutador telefonico automatico (eq. De com., cinemat. O fotograf.)	Pieza
10494	56500068	Conmutador telegrafico (eq. De com., cinemat. O fotograf.)	Pieza
10495	56500069	Control de giro de antena (aparato) (eq. De com., cinemat. O fotograf.)	Pieza
10496	56500070	Controlador de frecuencia (radiocomunicacion) (instrumento cientifico)	Pieza
10497	56500071	Corrector de parametros para video (eq. De com., cinemat. O fotograf.)	Pieza
10498	56500072	Corrector de voltaje (eq. Electrico)	Pieza
10499	56500073	Correctores de base de tiempo (eq. De com., cinemat. O fotograf.)	Pieza
10500	56500074	Deck de audio (eq. De reproduccion)	Pieza
10501	56500075	Deck estereo (eq. De reproduccion)	Pieza
10502	56500076	Decodificador (eq. De reproduccion)	Pieza
10503	56500077	Demodulador (eq. De com., cinemat. O fotograf.)	Pieza
10504	56500078	Descanalizador (enlace telefonia) (eq. De reproduccion)	Pieza
10505	56500079	Detector de cristal (capta ondas inalambricas) (eq. De reproduccion)	Pieza
10506	56500080	Detector de perturbaciones electromagneticas (eq. De reproduccion)	Pieza
10507	56500081	Detector sintetizador de señales (eq. De com., cinemat. O fotograf.)	Pieza
10508	56500082	Display de analizador de espectros (eq. De reproduccion)	Pieza
10509	56500083	Dispositivo programador de frecuencias en equipos portatiles (eq. De com., cinemat. O fotograf.)	Pieza
10510	56500084	Distribuidor de señal (eq. De reproduccion)	Pieza
10511	56500085	Distribuidor de video (eq. De com., cinemat. O fotograf.)	Pieza
10512	56500086	Domo antena (eq. De com., cinemat. O fotograf.)	Pieza
10513	56500087	Equipo analizador de parametros de semiconductores (eq. De com., cinemat. O fotograf.)	Pieza
10514	56500088	Equipo celular de localizacion de vehiculos (ant.cel.y sat.bat.rast.y boton panico frontal (eq. De com., cinemat. O fotograf.)	Pieza
10515	56500089	Equipo correo de voz (equipo de procesamiento y almacenamiento de mensajes de voz) (eq. De com., cinemat. O fotograf.)	Pieza
10516	56500090	Equipo cuenta vueltas (eq. Electrico)	Pieza
10517	56500091	Equipo de audio y videograbacion en boton (eq. De com., cinemat. O fotograf.)	Pieza
10518	56500092	Equipo de audio y videograbacion en chamarra (eq. De com., cinemat. O fotograf.)	Pieza
10519	56500093	Equipo de microondas (eq. De com., cinemat. O fotograf.)	Pieza
10520	56500094	Equipo de onda portadora "carrier" (eq. De com., cinemat. O fotograf.)	Pieza
10521	56500095	Equipo de seguridad tipo hardware, con protocolos y estandares de seguridad (eq. De computacion)	Pieza
10522	56500096	Equipo de videograbacion en telefono celular (eq. De com., cinemat. O fotograf.)	Pieza
10523	56500097	Equipo para analizar señales (eq. de com., cinemat. o fotograf.)	Pieza
10524	56500098	Equipo para direccionar antenas (eq. De com., cinemat. O fotograf.)	Pieza
10525	56500099	Equipo para instalacion de antena (eq. De com., cinemat. O fotograf.)	Pieza
10526	56500100	Equipo para orientar antenas (eq. De com., cinemat. O fotograf.)	Pieza
10527	56500101	Equipo para video conferencia (eq. De reproduccion)	Pieza
10528	56500102	Radar	Pieza
10529	56500103	Equipo selector de antena (eq. De com., cinemat. O fotograf.)	Pieza
10530	56500104	Equipo silenciador del transmisor de señales (eq. De com., cinemat. O fotograf.)	Pieza
10531	56500105	Equipo sonar (eq. De com., cinemat. O fotograf.)	Pieza
10532	56500106	Equipo telex y facsimil (eq. De com., cinemat. O fotograf.)	Pieza
10533	56500107	Equipos de navegacion aerea (eq. De com., cinemat. O fotograf.)	Pieza
10534	56500108	Equipos de navegacion maritima (eq. De com., cinemat. O fotograf.)	Pieza
10535	56500109	Equipos y aparatos telegraficos (eq. De com., cinemat. O fotograf.)	Pieza
10536	56500110	Estacion repetidora (eq. De com., cinemat. O fotograf.)	Pieza
10537	56500111	Fuente de estroboscopio (eq. De reproduccion)	Pieza
10538	56500112	Fuente de impedancia (eq. De reproduccion)	Pieza
10539	56500113	Generador barras color (eq. De com., cinemat. O fotograf.)	Pieza
10540	56500114	Generador de caracteres (eq. De com., cinemat. O fotograf.)	Pieza
10541	56500115	Generador de señal (eq. De com., cinemat. O fotograf.)	Pieza
10542	56500116	Generador de sincronia (eq. De com., cinemat. O fotograf.)	Pieza
10543	56500117	Intercomunicador (red privada) (eq. De com., cinemat. O fotograf.)	Pieza
10544	56500118	Interfase de audio (eq. De com., cinemat. O fotograf.)	Pieza
10545	56500119	Interfase de sincronia (eq. De com., cinemat. O fotograf.)	Pieza
10546	56500120	Juego de calibracion para transistores (eq. Electrico)	Pieza
10547	56500121	Llamador onda corta (eq. De com., cinemat. O fotograf.)	Pieza
10548	56500122	Localizador de sonidos (eq. De com., cinemat. O fotograf.)	Pieza
10549	56500123	Manipulador (eq. De com., cinemat. O fotograf.)	Pieza
10550	56500124	Maquina lumitipia (eq. De com., cinemat. O fotograf.)	Pieza
10551	56500125	Medidor nivel tipo fs-sk (eq. De com., cinemat. O fotograf.)	Pieza
10552	56500126	Mezcladora (eq. De com., cinemat. O fotograf.)	Pieza
10553	56500127	Micro camara oculta con accesorios (eq. De com., cinemat. O fotograf.)	Pieza
10554	56500128	Microtelefono prueba (eq. De com., cinemat. O fotograf.)	Pieza
10555	56500198	Tira de parcheo (eq. De com., cinemat. O fotograf.)	Pieza
10556	56500129	Mini grabadora digital de video (mini dvr) (eq. De com., cinemat. O fotograf.)	Pieza
10557	56500130	Modulador radial (eq. De com., cinemat. O fotograf.)	Pieza
10558	56500131	Modulo de distribucion de energia a equipos de monitoreo (eq. De com., cinemat. O fotograf.)	Pieza
10559	56500132	Modulo generador de señales radioelectricas (eq. De com., cinemat. O fotograf.)	Pieza
10560	56500133	Modulo solar (eq. De com., cinemat. O fotograf.)	Pieza
10561	56500134	Monitor de radiocomunicacion (eq. De com., cinemat. O fotograf.)	Pieza
10562	56500135	Multiplexor modular (eq. De computacion)	Pieza
10563	56500136	Multiplicador lineas (eq. De com., cinemat. O fotograf.)	Pieza
10564	56500137	Navegador satelital (eq. De com., cinemat. O fotograf.)	Pieza
10565	56500138	Panel de control ado. (eq. De com., cinemat. O fotograf.)	Pieza
10566	56500139	Panel receptor fm (eq. De com., cinemat. O fotograf.)	Pieza
10567	56500140	Panel transmisor fm (eq. De com., cinemat. O fotograf.)	Pieza
10568	56500141	Pantalla de informacion de monitoreo (eq. De com., cinemat. O fotograf.)	Pieza
10569	56500142	Perforadora cintas telex (eq. De com., cinemat. O fotograf.)	Pieza
10570	56500143	Perforadora clave morse (eq. De com., cinemat. O fotograf.)	Pieza
10571	56500144	Pistofono (instrumento para obtener presion acustica) (instrumento cientifico)	Pieza
10572	56500145	Prisma solar sencillo, doble transito (eq. De com., cinemat. O fotograf.)	Pieza
10573	56500146	Probador de cabezas de video (eq. De com., cinemat. O fotograf.)	Pieza
10574	56500147	Probador de cables (eq. Electrico)	Pieza
10575	56500148	Procesador de video (eq. De com., cinemat. O fotograf.)	Pieza
10576	56500149	Procesador heterodino (comunicacion) (eq. De com., cinemat. O fotograf.)	Pieza
10577	56500150	Procesador periferico (comunicacion) (eq. De com., cinemat. O fotograf.)	Pieza
10578	56500151	Protector de linea de corriente alterna (eq. De com., cinemat. O fotograf.)	Pieza
10579	56500152	Radio control sonido (eq. De com., cinemat. O fotograf.)	Pieza
10580	56500153	Radio goniometro (eq. De com., cinemat. O fotograf.)	Pieza
10581	56500154	Radio localizador via satelite (eq. De com., cinemat. O fotograf.)	Pieza
10582	56500155	Radio onda corta y/o larga (transmisor y receptor) (eq. De com., cinemat. O fotograf.)	Pieza
10583	56500156	Radio orientador (eq. De com., cinemat. O fotograf.)	Pieza
10584	56500157	Radio receptor fm-wt (eq. De com., cinemat. O fotograf.)	Pieza
10585	56500158	Raton para equipos de monitoreo (mouse trak) (eq. De com., cinemat. O fotograf.)	Pieza
10586	56500159	Receptor de monitoreo (eq. De com., cinemat. O fotograf.)	Pieza
10587	56500160	Receptor de señal (eq. De com., cinemat. O fotograf.)	Pieza
10588	56500161	Receptor para microfono (eq. De com., cinemat. O fotograf.)	Pieza
10589	56500162	Receptor scanner de señales (eq. De com., cinemat. O fotograf.)	Pieza
10590	56500163	Receptor sistema navegacion (eq. De com., cinemat. O fotograf.)	Pieza
10591	56500164	Receptor y decodificador (satelital) (eq. De com., cinemat. O fotograf.)	Pieza
10592	56500165	Regulador de señal (hace pruebas en la señal p/buena recepcion) (eq. De com., cinemat. O fotograf.)	Pieza
10593	56500166	Regulador/controlador de carga para modulos fotovoltaicos (eq. De com., cinemat. O fotograf.)	Pieza
10594	56500167	Rejuvenecedor pantalla t.v. (eq. De com., cinemat. O fotograf.)	Pieza
10595	56500168	Repetidor carrier (eq. De com., cinemat. O fotograf.)	Pieza
10596	56500169	Repetidor telefonico (eq. De com., cinemat. O fotograf.)	Pieza
10597	56500170	Repetidor telex (eq. De com., cinemat. O fotograf.)	Pieza
10598	56500171	Reproductor de discos de video digital (dvd) (eq. De com., cinemat. O fotograf.)	Pieza
10599	56500172	Reproductor de discos de video digital (dvd) y videocasetera (tipo combo)  (eq. De com., cinemat. O fotograf.)	Pieza
10600	56500173	Restrictor lada telefonico (eq. De com., cinemat. O fotograf.)	Pieza
10601	56500174	Retransmisor telegrafico (eq. De com., cinemat. O fotograf.)	Pieza
10602	56500175	Reverberador (instrumento cientifico)	Pieza
10603	56500176	Satelite (eq. De com., cinemat. O fotograf.)	Pieza
10604	56500177	Selector de frecuencia (eq. De com., cinemat. O fotograf.)	Pieza
10605	56500178	Servidor de comunicacion de telefonia via red (eq. De com., cinemat. O fotograf.)	Pieza
10606	56500179	Sistema analizador de distorsion (eq. De com., cinemat. O fotograf.)	Pieza
10607	56500180	Sistema de comunicacion de voz y datos (eq. De com., cinemat. O fotograf.)	Pieza
10608	56600036	Contacto magnetico (eq. Electrico)	Pieza
10609	56500181	Sistema de control de emisiones radioelectricas (eq. de com., cinemat. o fotograf.)	Pieza
10610	56500182	Sistema de control de acceso (eq. De com., cinemat. O fotograf.)	Pieza
10611	56500183	Sistema de efectos opticos digitales ado. (eq. De com., cinemat. O fotograf.)	Pieza
10612	56500184	Sistema de intercepcion de radiolocalizadores (eq. De com., cinemat. O fotograf.)	Pieza
10613	56500185	Sistema de intercepcion de telefonia celular (eq. De com., cinemat. O fotograf.)	Pieza
10614	56500186	Sistema de intercepcion y monitoreo de fax (eq. De com., cinemat. O fotograf.)	Pieza
10615	56500187	Sistema de vigilancia de audio a traves de pared (eq. De com., cinemat. O fotograf.)	Pieza
10616	56500188	Sistema de vigilancia laser (eq. De com., cinemat. O fotograf.)	Pieza
10617	56500189	Tablero de conectores (eq. De com., cinemat. O fotograf.)	Pieza
10618	56500190	Tablero de control  (eq. De com., cinemat. O fotograf.)	Pieza
10619	56500191	Telefono celular (eq. De com., cinemat. O fotograf.)	Pieza
10620	56500192	Telefono fijo satelital (eq. De com., cinemat. O fotograf.)	Pieza
10621	56500193	Telefono intersecretarial (eq. De com., cinemat. O fotograf.)	Pieza
10622	56500194	Telefono movil satelital (maritimo, vehicular, etc.) (eq. De com., cinemat. O fotograf.)	Pieza
10623	56500195	Telefono satelital (eq. De com., cinemat. O fotograf.)	Pieza
10624	56500196	Telegrafo (eq. De com., cinemat. O fotograf.)	Pieza
10625	56500197	Teleimpresora (eq. De reproduccion)	Pieza
10626	56500199	Tira de parcheo de tiempo (eq. De com., cinemat. O fotograf.)	Pieza
10627	56500200	Transformador audio frecuencia (eq. De com., cinemat. O fotograf.)	Pieza
10628	56500201	Transmisor de señal (eq. De com., cinemat. O fotograf.)	Pieza
10629	56500202	Transmisor electronico de presion estatica (eq. De com., cinemat. O fotograf.)	Pieza
10630	56500203	Transmisor indicador revoluciones y telegrafos a maquina (eq. De com., cinemat. O fotograf.)	Pieza
10631	56500204	Transmisor para microfono (eq. De com., cinemat. O fotograf.)	Pieza
10632	56500205	Transmisor receptor radio telefonico (eq. De com., cinemat. O fotograf.)	Pieza
10633	56500206	Transreceptor (eq. De reproduccion)	Pieza
10634	56500207	Trazador y amplificador inductivo (eq. De com., cinemat. O fotograf.)	Pieza
10635	56500208	Unidad de control de rotacion de equipos y funciones (eq. De com., cinemat. O fotograf.)	Pieza
10636	56500209	Unidad de distorsion de energia (eq. De com., cinemat. O fotograf.)	Pieza
10637	56500210	Unidad de intercambio de señales ado. (eq. De com., cinemat. O fotograf.)	Pieza
10638	56500211	Unidad de sintonia de señales radioelectricas (eq. De com., cinemat. O fotograf.)	Pieza
10639	56500212	Unidad ecosonda uso general (eq. De com., cinemat. O fotograf.)	Pieza
10640	56500213	Unidad selector de audio  (eq. De com., cinemat. O fotograf.)	Pieza
10641	56500214	Unidad telegrafos del magistral (eq. De com., cinemat. O fotograf.)	Pieza
10642	56500215	Walkie-talkie (eq. De com., cinemat. O fotograf.)	Pieza
10643	56500216	Correo neumatico	Pieza
10644	56500217	Sistema de control de rondas	Pieza
10645	56500218	Radio transreceptor	Pieza
10646	56500219	Sistema de grabacion movil	Pieza
10647	56500220	Transpondedor/transponder	Pieza
10648	5660	Equipos de generacion electrica, aparatos y accesorios electricos	
10649	56601	Maquinaria y equipo electrico y electronico	
10650	56600001	Alarma electrica (eq. Electrico)	Pieza
10651	56600002	Alarma sonora (eq. Electrico)	Pieza
10652	56600003	Alternador (eq. Electrico)	Pieza
10653	56600004	Amplificador de impulsos (eq. De com., cinemat. O fotograf.)	Pieza
10654	56600005	Analizador de altura (instrumento cientifico)	Pieza
10655	56600006	Analizador de mercurio (aparato cientifico)	Pieza
10656	56600007	Analizador multicanal (aparato cientifico)	Pieza
10657	56600008	Aparato analizador de cableado red (eq. Electrico)	Pieza
10658	56600009	Aparato limpiador y probador bujias (eq. Electrico)	Pieza
10659	56600010	Aparato para conexiones (switchera) (eq. Electrico)	Pieza
10660	56600011	Arrancador o autostater (eq. Electrico)	Pieza
10661	56600012	Aspirador de aire (limpieza centrales electricas)	Pieza
10662	56600013	Auto transformador (eq. Electrico)	Pieza
10663	56600014	Autotransformador	Pieza
10664	56600015	Autotransformador para arranque de motores	Pieza
10665	56600016	Autotransformador para servicio continuo	Pieza
10666	56600017	Banco de baterias con electrolito libre (almacena energia electrica captada por energia solar) (eq. Electrico)	Pieza
10667	56600018	Banco de resistencias (hasta 5000 amperes, hasta 34500 volts. En 3 fases) (eq. Electrico)	Pieza
10668	56600019	Bateria o acumulador industrial (eq. Electrico)	Pieza
10669	56600020	Caja controladora de temperatura (eq. Electrico)	Pieza
10670	56600021	Caja controladora de ventilacion en equipos de monitoreo (eq. Electrico)	Pieza
10671	56600022	Caja para baterias para accionar planta de luz (eq. Electrico)	Pieza
10672	56600023	Caja selector de ampers (eq. Electrico)	Pieza
10673	56600024	Calentador de agua procesadora de peliculas de microfichas (eq. De com., cinemat. O fotograf.)	Pieza
10674	56600025	Calzadora de via	Pieza
10675	56600026	Cargador baterias (eq. Electrico)	Pieza
10676	56600027	Cargador corriente (eq. Electrico)	Pieza
10677	56600028	Cargador pilas (eq. Electrico)	Pieza
10678	56600029	Caseta metalica para muestreo (aparato cientifico)	Pieza
10679	56600030	Caseta para muestreo de aire ambiental (aparato cientifico)	Pieza
10680	56600031	Caseta para practicas de soldadura	Pieza
10681	56600032	Centro de maquinado vertical computarizado cnc	Pieza
10682	56600033	Checador diodos y transistores (eq. Electrico)	Pieza
10683	56600034	Cintilometro mont (aparato cientifico)	Pieza
10684	56600035	Condensador (eq. Electrico)	Pieza
10685	5910	Software	
10686	56600037	Contador beta (aparato cientifico)	Pieza
10687	56600038	Contador de centelleo (aparato cientifico)	Pieza
10688	56600039	Contador geiger (aparato cientifico)	Pieza
10689	56600040	Desmagnetizador (eq. Electrico)	Pieza
10690	56600041	Detector automess y teletector (aparato cientifico)	Pieza
10691	56600042	Detector cintilador (aparato cientifico)	Pieza
10692	56600043	Detector de barrera (aparato cientifico)	Pieza
10693	56600044	Detector de centelleo (aparato cientifico)	Pieza
10694	56600045	Detector de germanio hiperpuro (aparato cientifico)	Pieza
10695	56600046	Detector eda (aparato cientifico)	Pieza
10696	56600047	Detector geiger (aparato cientifico)	Pieza
10697	56600048	Detector victoreen (aparato cientifico)	Pieza
10698	56600049	Detector y tubo detector para neutrones (aparato cientifico)	Pieza
10699	56600050	Distribuidor de antena (tablero) (eq. Electrico)	Pieza
10700	56600051	Ecualizador (eq. De com., cinemat. O fotograf.)	Pieza
10701	56600052	Electromagneto (eq. Electrico)	Pieza
10702	56600053	Equipo afinacion electronico (herramienta	Pieza
10703	56600054	Equipo analizador de uranio (aparato cientifico)	Pieza
10704	56600055	Equipo analizador electronico (herramienta	Pieza
10705	56600056	Equipo analizador-motores combustion interna (herramienta	Pieza
10706	56600057	Equipo completo de carburacion (herramienta	Pieza
10707	56600058	Equipo dasa	Pieza
10708	57600008	Mula (ganado equino)	Pieza
10709	56600059	Equipo electrico operar compuertas (eq. Electrico)	Pieza
10710	56600060	Equipo para medir y corregir vibraciones en helice o rotor	Pieza
10711	56600061	Equipos convertidores (eq. Electrico)	Pieza
10712	56600062	Estacion de pruebas para verificacion de medidores de agua (herramienta	Pieza
10713	56600063	Filtro de vacio con embudo (aparato cientifico)	Pieza
10714	56600064	Filtro optico (aparato cientifico)	Pieza
10715	56600065	Fuente alimentacion (eq. Electrico)	Pieza
10716	56600066	Fuente calibrada de gas radon (aparato cientifico)	Pieza
10717	56600067	Fuente de verificacion (aparato cientifico)	Pieza
10718	56600068	Fuente radioactiva de cesio (aparato cientifico)	Pieza
10719	56600069	Generador corriente alterna (eq. Electrico)	Pieza
10720	56600070	Generador corriente continua (eq. Electrico)	Pieza
10721	56600071	Generador de modulacion am fm (instrumento cientifico)	Pieza
10722	56600072	Generador y probador de tonos (identifica y rastrea lineas de cableado) (eq. Electrico)	Pieza
10723	56600073	Invertidor consola (eq. Electrico)	Pieza
10724	56600074	Laboratorio diagnostico motores diesel (herramienta	Pieza
10725	56600075	Lampara tiempo (herramienta	Pieza
10726	56600076	Lapiz de vacio (aparato de dosificacion para montar componentes) (eq. Electrico)	Pieza
10727	56600077	Maleta porta antena (eq. Electrico)	Pieza
10728	56600078	Mascara ultralite (aparato cientifico)	Pieza
10729	56600079	Medidor de capacitores (aparato cientifico)	Pieza
10730	56600080	Medidor de distorsion (eq. Electrico)	Pieza
10731	56600081	Medidor de factor antena (eq. Electrico)	Pieza
10732	56600082	Medidor de flujo (aparato cientifico)	Pieza
10733	56600083	Medidor de frecuencia (eq. Electrico)	Pieza
10734	56600084	Medidor de impedancia (eq. Electrico)	Pieza
10735	56600085	Medidor de intensidad (eq. Electrico)	Pieza
10736	56600086	Medidor de potencia optica (eq. Electrico)	Pieza
10737	56600087	Medidor de radiacion (aparato cientifico)	Pieza
10738	56600088	Medidor de radiaciones alfa (aparato cientifico)	Pieza
10739	56600089	Medidor de ruido (eq. Electrico)	Pieza
10740	56600090	Medidor de tension (eq. Electrico)	Pieza
10741	56600091	Medidor de voltaje (eq. Electrico)	Pieza
10742	56600092	Medidor para gas (aparato cientifico)	Pieza
10743	56600093	Medidor proporcional para alfas (aparato cientifico)	Pieza
10744	56600094	Medidor thyac iii (aparato cientifico)	Pieza
10745	56600095	Medidor tipo camara de ionizacion (aparato cientifico)	Pieza
10746	56600096	Medidor tipo de ionizacion (aparato cientifico)	Pieza
10747	56600097	Medidor y tubo detector para neutrones (aparato cientifico)	Pieza
10748	56600098	Modem filtro portador electrico (eq. para comercios)	Pieza
10749	56600099	Modulo inductancia (eq. Electrico)	Pieza
10750	56600100	Modulo medicion (eq. Electrico)	Pieza
10751	56600101	Modulo transformador (eq. Electrico)	Pieza
10752	56600102	Modulos capacitancia (eq. Electrico)	Pieza
10753	56600103	Multicanal camberra (aparato cientifico)	Pieza
10754	56600104	Multicanal portatil (aparato cientifico)	Pieza
10755	56600105	Multiprobador (eq. Electrico)	Pieza
10756	56600106	Pararrayos y apartarrayos (eq. Electrico)	Pieza
10757	56600107	Planta fuerza portatil (eq. Electrico)	Pieza
10758	56600108	Planta luz emergencia (eq. Electrico)	Pieza
10759	56600109	Planta para soldar (eq. Electrico)	Pieza
10760	56600110	Potenciometro (eq. Electrico)	Pieza
10761	56600111	Probador amperaje (eq. Electrico)	Pieza
10762	56600112	Probador armaduras (eq. Electrico)	Pieza
10763	56600113	Probador baterias (eq. Electrico)	Pieza
10764	56600114	Probador bobinas (eq. Electrico)	Pieza
10765	56600115	Probador bulbos (eq. Electrico)	Pieza
10766	56600116	Probador de vacio (aparato cientifico)	Pieza
10767	56600117	Probador relacion transformador (eq. Electrico)	Pieza
10768	56600118	Probador resistencias (eq. Electrico)	Pieza
10769	56600119	Probador voltaje (eq. Electrico)	Pieza
10770	56600120	Puntas de prueba con atenuacion (instrumento cientifico)	Pieza
10771	56600121	Receptor corriente (eq. Electrico)	Pieza
10772	56600122	Reflector ciclos de luz (eq. Electrico)	Pieza
10773	56600123	Reflector de haz de luz abierta e intensa (eq. Electrico)	Pieza
10774	56600124	Reflector luz abierta (eq. Electrico)	Pieza
10775	56600125	Reflector luz ajustable (eq. Electrico)	Pieza
10776	56600126	Reflector luz de halogeno con espejo parabolico y cristal difusor (eq. Electrico)	Pieza
10777	56600127	Reflector luz elipsoidal (eq. Electrico)	Pieza
10778	56600128	Reflector luz fluorescente portatil (eq. Electrico)	Pieza
10779	56600129	Reflector luz fria (eq. Electrico)	Pieza
10780	56600130	Reflector luz intensa (eq. Electrico)	Pieza
10781	56600131	Reflector luz que apunta de manera precisa a persona u objeto (eq. Electrico)	Pieza
10782	56600132	Reflector luz rebotada (no directa) (eq. Electrico)	Pieza
10783	56600133	Reflector luz robotica (eq. Electrico)	Pieza
10784	56600134	Reflector luz suave (eq. Electrico)	Pieza
10785	56600135	Regulador corriente, voltaje y de tension (eq. Electrico)	Pieza
10786	56600136	Semaforo fiscal	Pieza
10787	56600137	Separador magnetico (eq. Electrico)	Pieza
10788	56600138	Sistema completo para analisis de material radioactivo en el cuerpo (aparato cientifico)	Pieza
10789	56600139	Sistema contador de bajo fondo (aparato cientifico)	Pieza
10790	56600140	Sistema de disimetria thermolumiscente (aparato cientifico)	Pieza
10791	56600141	Sistema de entrenamiento en detector de fallas (para practicas) (instrumento cientifico)	Pieza
10792	56600142	Sistema de entrenamiento para control de motores (para practicas) (instrumento cientifico)	Pieza
10793	56600143	Sistema deteccion bajo fondo (aparato cientifico)	Pieza
10794	56600144	Sistema gobierno electro hidraulico (eq. Electrico)	Pieza
10795	56600145	Sistema para realizar disimetria termoluminiscente (aparato cientifico)	Pieza
10796	56600146	Soldadora de pernos	Pieza
10797	56600147	Subestaciones electricas elevadoras (eq. Electrico)	Pieza
10798	56600148	Subestaciones electricas reductoras (eq. Electrico)	Pieza
10799	56600149	Subestaciones electricas unitarias (eq. Electrico)	Pieza
10800	56600150	Tablero de control para sistema de deteccion de humo	Pieza
10801	56600151	Tablero transferencias (eq. Electrico)	Pieza
10802	56600152	Tarjeta electronica (eq. De com., cinemat. O fotograf.)	Pieza
10803	56600153	Transformador  de potencia (eq. Electrico)	Pieza
10804	56600154	Transformador de control (eq. Electrico)	Pieza
10805	56600155	Transformador de corriente (eq. Electrico)	Pieza
10806	56600156	Transformador de potencial (eq. Electrico)	Pieza
10807	56600157	Tripie para antena (eq. Electrico)	Pieza
10808	56600158	Tubo detector (aparato cientifico)	Pieza
10809	56600159	Tubo detector alfa beta gamma (aparato cientifico)	Pieza
10810	56600160	Tubo detector para alfas (aparato cientifico)	Pieza
10811	56600161	Tubo detector para betas (aparato cientifico)	Pieza
10812	56600162	Tubo detector para tritium (aparato cientifico)	Pieza
10813	56600163	Unidad de sincrotransformador (instrumento cientifico)	Pieza
10814	56600164	Unidad emergencia para alumbrado (con baterias) (eq. Electrico)	Pieza
10815	56600165	Unidad preamplificadora de corriente alterna (instrumento cientifico)	Pieza
10816	56600166	Unidad simuladora de revelador (instrumento cientifico)	Pieza
10817	56600167	Unidad sincrodiferencial (instrumento cientifico)	Pieza
10818	56600168	Laboratorio electronico	Pieza
10819	56600169	Acuario de cristal para acuacultura	Pieza
10820	56600170	Filtro de luz ultravioleta para acuarios de acuacultura	Pieza
10821	56600171	Simulador de ph	Pieza
10822	56600172	Unidad de digestion	Pieza
10823	56600173	Criptometro	Pieza
10824	56600174	Equipo para determinacion de aceite de parafina	Pieza
10825	56600175	Block intercambiable gradiente	Pieza
10826	56600176	Biofotometro	Pieza
10827	56600177	Kit basico de colector de vac	Pieza
10828	56600178	Block para baño seco	Pieza
10829	56600179	Reactor para dqo (demanda quimica de oxigeno)	Pieza
10830	56600180	Block para baños de temperatura de tubos de laboratorio (eppendorf)	Pieza
10831	56600181	Tanque o contenedor de nitrogeno	Pieza
10832	56600182	Darkroom (fotodocumentador de imagenes) incluye camara ccd	Pieza
10833	56600183	Sistema detector de secuencias	Pieza
10834	56600184	Robot humanoide	Pieza
10835	56600185	Automatico para cisterna	Pieza
10836	56600186	Torre de iluminacion	Pieza
10837	56600187	Panel solar	Pieza
10838	56600188	Maquinas para juegos de azar	Pieza
10839	5670	Herramientas y maquinas-herramienta	
10840	56701	Herramientas y maquinas herramienta	
10841	56700001	Abecedario mando neumatico	Pieza
10842	56700002	Acanalador (herramienta)	Pieza
10843	56700003	Aditamento corte arco para autogena (herramienta)	Pieza
10844	56700004	Afiladora manual (herramienta)	Pieza
10845	56700005	Alambradora (herramienta)	Pieza
10846	56700006	Alimentador pintura (herramienta)	Pieza
10847	56700007	Amoladora neumatica (madera, piedra, metal y plastico)	Pieza
10848	56700008	Aparato de diseño e impresion de etiquetas de seguridad (guilloche)	Pieza
10849	56700009	Aparato de elaboracion de placas de identificacion	Pieza
10850	56700010	Aparato engomador de pastas (encuadernacion)	Pieza
10851	56700011	Aparato enrollador de cable (eq. Electrico)	Pieza
10852	56700012	Atornilladora electrica	Pieza
10853	56700013	Balanceadora	Pieza
10854	56700014	Banco taller (herramienta)	Pieza
10855	56700015	Base empotrar talacho (herramienta)	Pieza
10856	56700016	Base esmeril (herramienta)	Pieza
10857	56700017	Bastidor (herramienta)	Pieza
10858	56700018	Brochadora (madera, metal, piedra y plastico	Pieza
10859	56700019	Bruñidora (madera, metal, piedra y plastico)	Pieza
10860	56700020	Cabezal divisor (fabricacion de engranes)	Pieza
10861	56700021	Caladora	Pieza
10862	56700022	Cama mecanico (herramienta)	Pieza
10863	56700023	Canteadora (madera, metal, piedra y plastico)	Pieza
10864	56700024	Cantonera (herramienta)	Pieza
10865	56700025	Carrete arco	Pieza
10866	56700026	Carretilla (herramienta)	Pieza
10867	56700027	Carro transportador oxigeno (herramienta)	Pieza
10868	56700028	Cepilladora (madera, metal, piedra y plastico)	Pieza
10869	56700029	Cizalla electrica (madera, metal, piedra y plastico)	Pieza
10870	56700030	Compas pailero (herramienta)	Pieza
10871	56700031	Copiadora llaves	Pieza
10872	56700032	Cortadora de disco	Pieza
10873	56700033	Cortadora de plasma	Pieza
10874	56700034	Cortadora de precision (corta secciones de muestras pequeñas con precision)	Pieza
10875	56700035	Corte flejes (herramienta)	Pieza
10876	56700036	Cosedora papel	Pieza
10877	56700037	Cubeta-bomba grasa (herramienta)	Pieza
10878	56700038	Cuchilla hidraulica con rodillo	Pieza
10879	56700039	Descarbonizador (herramienta)	Pieza
10880	56700040	Destrabador (herramienta)	Pieza
10881	56700041	Diablo limpiar tuberias (herramienta)	Pieza
10882	56700042	Dilatador (manual) (herramienta)	Pieza
10883	56700043	Doblador tubos (manual) (herramienta)	Pieza
10884	56700044	Dobladora de riel	Pieza
10885	56700045	Encuadernadora	Pieza
10886	56700046	Enderezador carroceria (herramienta)	Pieza
10887	56700047	Enderezadora flechas (herramienta)	Pieza
10888	56700048	Ensambladora	Pieza
10889	56700049	Entalladora de durmiente	Pieza
10890	56700050	Equipo alineador direccion auto (herramienta)	Pieza
10891	56700051	Equipo lubricacion (herramienta)	Pieza
10892	56700052	Equipo para medir esfuerzo de tension, comprension y adhesion de materiales	Pieza
10893	56700053	Escareadora (madera, metal, piedra y plastico)	Pieza
10894	56700054	Escoplo (maquinas-herramientas)	Pieza
10895	56700055	Esmeriladora (maquinas-herramientas)	Pieza
10896	56700056	Expansor (manual) (herramienta)	Pieza
10897	56700057	Extractor flechas (herramienta)	Pieza
10898	56700058	Flejadora (herramienta)	Pieza
10899	56700059	Forjadora (para metal, piedra y plastico)	Pieza
10900	56700060	Fragua (manual) (herramienta)	Pieza
10901	56700061	Fresa (herramienta)	Pieza
10902	56700062	Fresadora (para metal, piedra y plastico)	Pieza
10903	56700063	Fuelle (herramienta)	Pieza
10904	56700064	Gato rana para calzar	Pieza
10905	56700065	Grabador (herramienta)	Pieza
10906	56700066	Impactores en cascada (recolecta muestras de particulas)	Pieza
10907	56700067	Inyector grasa (herramienta)	Pieza
10908	56700068	Levanta tijera (herramienta)	Pieza
10909	56700069	Levanta valvulas (herramienta)	Pieza
10910	56700070	Lijadora portatil	Pieza
10911	56700071	Lijadoras (para metal, piedra, plastico)	Pieza
10912	56700072	Limpiadora portatil de presion	Pieza
10913	56700073	Llave dinamometrica (torquimetro) (herramienta)	Pieza
10914	56700074	Llave impacto neumatica	Pieza
10915	56700075	Machimbrador (herramienta)	Pieza
10916	56700076	Machueladora (para madera, metal y plastico)	Pieza
10917	56700077	Mandriladora (madera, metal y plastico) (herramienta)	Pieza
10918	56700078	Manguito conico perforacion (herramienta)	Pieza
10919	56700079	Maquina combinada carpinteria	Pieza
10920	56700080	Maquina foliadora	Pieza
10921	56700081	Maquina peluquero (electrica o mecanica) (herramienta)	Pieza
10922	56700082	Marcador vibro-tool	Pieza
10923	56700083	Martillo electrico	Pieza
10924	56700084	Martillo neumatico cincelar	Pieza
10925	56700085	Martillo neumatico remachar	Pieza
10926	56700086	Mondadora	Pieza
10927	56700087	Monta carga neumatica	Pieza
10928	56700088	Monta valvulas (herramienta)	Pieza
10929	56700089	Montacarga manual (herramienta)	Pieza
10930	56700090	Mortajadora (madera, metal, piedra, plastico	Pieza
10931	56700091	Motosierra	Pieza
10932	56700092	Niveladora de clutch	Pieza
10933	56700093	Nudo universal (herramienta)	Pieza
10934	56700094	Perforadora neumatica (vertical y horizontal)	Pieza
10935	56700095	Piernas neumaticas	Pieza
10936	56700096	Pirografo (herramienta)	Pieza
10937	56700097	Pistola emboquillar (herramienta)	Pieza
10938	56700098	Pistola grapas (herramienta)	Pieza
10939	56700099	Pistola neumatica pintar (herramienta)	Pieza
10940	56700100	Pistola para enrollar cable (eq. Electrico)	Pieza
10941	56700101	Pistola para sopletear aire (herramienta)	Pieza
10942	56700102	Pistola pintar (herramienta)	Pieza
10943	56700103	Pistola taquetes (herramienta)	Pieza
10944	56700104	Pluma hidraulica manual (herramienta)	Pieza
10945	56700105	Porta rollos p/fleje	Pieza
10946	56700106	Porta taladro	Pieza
10947	56700107	Postes (estante) (herramienta)	Pieza
10948	56700108	Prensa carpintero (herramienta)	Pieza
10949	56700109	Prensa electrohidraulica (para montar muestras que se estudiaran metalograficamente)	Pieza
10950	56700110	Prensa manual cadena (herramienta)	Pieza
10951	56700111	Prensa manual empacar forrajes (herramienta)	Pieza
10952	56700112	Prensa manual encorvar rieles (herramienta)	Pieza
10953	56700113	Prensa manual parches calientes (herramienta)	Pieza
10954	56700114	Prensa manual sellos goma (herramienta)	Pieza
10955	56700115	Prensa manual tubo (herramienta)	Pieza
10956	56700116	Prensa manual valvulas (herramienta)	Pieza
10957	56700117	Prensa mordaza (herramienta)	Pieza
10958	56700118	Pulidor bakelita (herramienta)	Pieza
10959	56700119	Pulidor cilindros (herramienta)	Pieza
10960	56700120	Punto de apoyo de piezas largas para torno (instrumento cientifico)	Pieza
10961	56700121	Punzonadora	Pieza
10962	56700122	Rampa hidraulica (herramienta)	Pieza
10963	56700123	Rebajadora (router)	Pieza
10964	56700124	Rebanador cilindros (herramienta)	Pieza
10965	56700125	Rebanadora	Pieza
10966	56700126	Rebordeadora	Pieza
10967	56700127	Reconstructora rodillos y ruedas	Pieza
10968	56700128	Rectificadora (madera, metal, piedra y plastico)	Pieza
10969	56700129	Rectificadora para tambores de frenos	Pieza
10970	56700130	Remachador balatas	Pieza
10971	56700131	Remachador neumatico	Pieza
10972	56700132	Remachadora neumatica (instrumento cientifico)	Pieza
10973	56700133	Rompe remaches (herramienta)	Pieza
10974	56700134	Segueta automatica	Pieza
10975	56700135	Separadora formas cuchilla	Pieza
10976	56700136	Sierra cinta	Pieza
10977	56700137	Sierra circular	Pieza
10978	56700138	Sierra electrica	Pieza
10979	56700139	Sierra multiple	Pieza
10980	56700140	Sierra neumatica	Pieza
10981	56700141	Sierra para riel	Pieza
10982	56700142	Soplete plomero (herramienta)	Pieza
10983	56700143	Soporte desarmar motores (herramienta)	Pieza
10984	56700144	Talador varilla (herramienta)	Pieza
10985	56700145	Taladradora manual (herramienta)	Pieza
10986	56700146	Taladro de precision (vertical)	Pieza
10987	56700147	Taladro electrico (madera, metal, piedra y plastico)	Pieza
10988	56700148	Taladro neumatico	Pieza
10989	56700149	Taladro para durmiente	Pieza
10990	56700150	Taladro para riel	Pieza
10991	56700151	Taladro radial	Pieza
10992	56700152	Tarraja (herramienta)	Pieza
10993	56700153	Termo sellador electrico	Pieza
10994	56700154	Tornillo banco (herramienta)	Pieza
10995	56700155	Trazador corte tuberia (herramienta)	Pieza
10996	56700156	Trenzadora	Pieza
10997	56700157	Triangulo (herramienta)	Pieza
10998	56700158	Tripie maniobra (herramienta)	Pieza
10999	56700159	Triscador	Pieza
11000	56700160	Trituradora papel	Pieza
11001	56700161	Trompo	Pieza
11002	56700162	Troqueladora (para madera, metal, plastico)	Pieza
11003	56700163	Yunque (herramienta)	Pieza
11004	56700164	Pistola (herramienta)	Pieza
11005	56700165	Podadora	Pieza
11006	56700166	Sujetadores de carga (perros)	Pieza
11007	56700167	Maquina para detallado de metales	Pieza
11008	56700168	Rotomartillo	Pieza
11009	56700169	Herramientas y accesorios para sofocacion de incendios	Pieza
11010	5690	Otros equipos	
11011	56901	Bienes muebles por arrendamiento financiero	
11012	56902	Otros bienes muebles	
11013	56900472	Puente colgante peatonal desmontable	Pieza
11014	56900475	Puente metalico desmontable	Pieza
11015	56900534	Sonda de temperatura de aire	Pieza
11016	56900609	Extintor	Pieza
11017	56900610	Bocina electromagnetica	Pieza
11018	56900642	Sistema contra incendio	Pieza
11019	56900645	Bolardo (poste de pequeña altura)	Pieza
11020	56900646	Accesorios para juegos de azar	Pieza
11021	56900647	Contenedor industrial de basura	Pieza
11022	56900648	Indicador de nivel	Pieza
11023	56900649	Barreras contenedoras	Pieza
11024	5700	Activos biologicos	
11025	5710	Bovinos	
11026	57101	Animales de reproduccion	
11027	57100001	Aberdeen-angus (ganado bovino)	Pieza
11028	57100002	Aburac (ganado bovino)	Pieza
11029	57100003	Alpina, francesa (ganado caprino)	Pieza
11030	57100004	Ayrshire (ganado bovino)	Pieza
11031	57100005	Cebu brahman (ganado bovino)	Pieza
11032	57100006	Cebu guzerat (ganado bovino)	Pieza
11033	57100007	Cebu gyr (ganado bovino)	Pieza
11034	57100008	Cebu indobrazil (ganado bovino)	Pieza
11035	57100009	Cebu nelore (ganado bovino)	Pieza
11036	57100010	Charolais (ganado bovino)	Pieza
11037	57100011	Chianina (ganado bovino)	Pieza
11038	57100012	Criollo (ganado bovino)	Pieza
11039	57100013	Cruza bovino (ganado bovino)	Pieza
11040	57100014	Herford (ganado bovino)	Pieza
11041	57100015	Holstein (ganado bovino)	Pieza
11042	57100016	Jersey (ganado bovino)	Pieza
11043	57100017	Limousin (ganado bovino)	Pieza
11044	57100018	Maine anjou (ganado bovino)	Pieza
11045	57100019	Red-pole (ganado bovino)	Pieza
11046	57100020	Salers (ganado bovino)	Pieza
11047	57100021	Simmental (ganado bovino)	Pieza
11048	57100022	Sta. Gertrudis (ganado bovino)	Pieza
11049	57100023	Suizo pardo (ganado bovino)	Pieza
11050	5720	Porcinos	
11051	57201	Porcinos	
11052	57200001	Cruza porcino (ganado porcino)	Pieza
11053	57200002	Duroc-jersey (ganado porcino)	Pieza
11054	57200003	Hampshire (ganado porcino)	Pieza
11055	57200004	Landrace (ganado porcino)	Pieza
11056	57200005	Pietrain (ganado porcino)	Pieza
11057	57200006	Yorkshire (ganado porcino)	Pieza
11058	5730	Aves	
11059	57301	Aves	
11060	5740	Ovinos y caprinos	
11061	57401	Ovinos y caprinos	
11062	57400001	Angora (ganado caprino)	Pieza
11063	57400002	Celtiberica (ganado caprino)	Pieza
11064	57400003	Corriedale (ganado ovino)	Pieza
11065	57400004	Criollo chiapas (ganado ovino)	Pieza
11066	57400005	Cruza caprino (ganado caprino)	Pieza
11067	57400006	Cruza ovino (ganado ovino)	Pieza
11068	57400007	Delaine (ganado ovino)	Pieza
11069	57400008	Dorset (ganado ovino)	Pieza
11070	57400009	Granadina (ganado caprino)	Pieza
11071	57400010	Hampshire (ganado ovino)	Pieza
11072	57400011	Kara kul (astrakan) (ganado ovino)	Pieza
11073	57400012	Mancha americana (ganado caprino)	Pieza
11074	57400013	Merino (ganado ovino)	Pieza
11075	57400014	Murciana (ganado caprino)	Pieza
11076	57400015	Nubia (ganado caprino)	Pieza
11077	57400016	Pelibuey (ganado ovino)	Pieza
11078	57400017	Rambouillet (ganado ovino)	Pieza
11079	57400018	Ronmey-marsh (ganado ovino)	Pieza
11080	57400019	Sannen (ganado caprino)	Pieza
11081	57400020	Suffolk (ganado ovino)	Pieza
11082	57400021	Toggenburg (ganado caprino)	Pieza
11083	5750	Peces y acuicultura	
11084	57501	Peces y acuicultura	
11085	57500001	Peces (animales vivos)	Pieza
11086	5760	Equinos	
11087	57601	Animales de reproduccion	
11088	57600001	Anglo arabe (ganado equino)	Pieza
11089	57600002	Arabe (ganado equino)	Pieza
11090	57600003	Asno (ganado equino)	Pieza
11091	57600004	Criollo (ganado equino)	Pieza
11092	57600005	Cruza equino (ganado equino)	Pieza
11093	57600006	Cuarto de milla (ganado equino)	Pieza
11094	57600007	Ingles (ganado equino)	Pieza
11095	5770	Especies menores y de zoologico	
11096	57701	Animales de custodia y vigilancia	
11097	57700001	Abejas (animales vivos)	Pieza
11098	57700003	Perro (animal de trabajo)	Pieza
11099	5780	Arboles y plantas	
11100	57801	Arboles y plantas	
11101	57800001	Agave (arboles o plantas)	Pieza
11102	57800002	Aguacate (arboles o plantas)	Pieza
11103	57800003	Alamo (arboles o plantas)	Pieza
11104	57800004	Albaricoquero (chabacano) (arboles o plantas)	Pieza
11105	57800005	Algodon (arboles o plantas)	Pieza
11106	57800006	Almendro (arboles o plantas)	Pieza
11107	57800007	Arbol, hule (caucho) (arboles o plantas)	Pieza
11108	57800008	Barbasco (arboles o plantas)	Pieza
11109	57800009	Cacao (arboles o plantas)	Pieza
11110	57800010	Cafeto (arboles o plantas)	Pieza
11111	57800011	Candelilla (arboles o plantas)	Pieza
11112	57800012	Canelo (arboles o plantas)	Pieza
11113	57800013	Caoba (arboles o plantas)	Pieza
11114	57800014	Capulin (arboles o plantas)	Pieza
11115	57800015	Cerezo (arboles o plantas)	Pieza
11116	57800016	Chabacano (arboles o plantas)	Pieza
11117	57800017	Ciruelo (arboles o plantas)	Pieza
11118	57800018	Ciruelo de almendras (arboles o plantas)	Pieza
11119	57800019	Durazno o duraznero (arboles o plantas)	Pieza
11120	57800020	Eucalipto (arboles o plantas)	Pieza
11121	57800021	Flores de todas clases (arboles o plantas)	Pieza
11122	57800022	Fresno (arboles o plantas)	Pieza
11123	57800023	Granado (arboles o plantas)	Pieza
11124	57800024	Guayabo (arboles o plantas)	Pieza
11125	57800025	Guayule (hule) (arboles o plantas)	Pieza
11126	57800026	Higuera (arboles o plantas)	Pieza
11127	57800027	Limero (arboles o plantas)	Pieza
11128	57800028	Limonero (arboles o plantas)	Pieza
11129	57800029	Mamey (arboles o plantas)	Pieza
11130	57800030	Mango (arboles o plantas)	Pieza
11131	57800031	Manzano (arboles o plantas)	Pieza
11132	57800032	Membrillero (arboles o plantas)	Pieza
11133	57800033	Naranjo (arboles o plantas)	Pieza
11134	57800034	Nogal (nuez castilla) (arboles o plantas)	Pieza
11135	57800035	Nogal (nuez encarcelada) (arboles o plantas)	Pieza
11136	57800036	Olivo (arboles o plantas)	Pieza
11137	57800037	Olmo (arboles o plantas)	Pieza
11138	57800038	Palma de coco (cocotero) (arboles o plantas)	Pieza
11139	57800039	Palma de datil (arboles o plantas)	Pieza
11140	57800040	Papayo (arboles o plantas)	Pieza
11141	57800041	Peral (arboles o plantas)	Pieza
11142	57800042	Pino (arboles o plantas)	Pieza
11143	57800043	Plantas de ornato (arboles o plantas)	Pieza
11144	57800044	Platano (platanero) (arboles o plantas)	Pieza
11145	57800045	Sargazo marino (arboles o plantas)	Pieza
11146	57800046	Sauce (arboles o plantas)	Pieza
11147	57800047	Tamarindo (arboles o plantas)	Pieza
11148	57800048	Tejocote (arboles o plantas)	Pieza
11149	57800049	Toronjo (arboles o plantas)	Pieza
11150	57800050	Vid (arboles o plantas)	Pieza
11151	57800051	Yuca (arboles o plantas)	Pieza
11152	57800052	Cempasuchil (arboles o plantas)	Pieza
11153	57800053	Biznaga (arboles o plantas)	Pieza
11154	57800054	Encino (arboles o plantas)	Pieza
11155	57800055	Holcus (arboles o plantas)	Pieza
11156	57800056	Jacaranda (arboles o plantas)	Pieza
11157	57800057	Kiwi (arboles o plantas)	Pieza
11158	57800058	Laurel (arboles o plantas)	Pieza
11159	57800059	Mejorana (arboles o plantas)	Pieza
11160	5790	Otros activos biologicos	
11161	57901	Otros activos biologicos	
11162	5800	Bienes inmuebles	
11163	5810	Terrenos	
11164	58101	Terrenos	
11165	5820	Viviendas	
11166	5830	Edificios no residenciales	
11167	58301	Edificios y locales	
11168	5890	Otros bienes inmuebles	
11169	58901	Adjudicaciones, exportaciones e indemnizaciones de inmuebles	
11170	58902	Bienes inmuebles en la modalidad de proyectos de infraestructura productiva de largo plazo	
11171	58903	Bienes inmuebles por arrendamiento financiero	
11172	58904	Otros bienes inmuebles	
11173	5900	Activos intangibles	
11174	59100001	Antivirus informatico	Pieza
11175	59100002	Todo tipo de software (paqueteria) (suministros informaticos)	Pieza
11176	59100003	Licencias de uso programas de computo	Pieza
11177	5920	Patentes	
11178	5930	Marcas	
11179	5940	Derechos	
11180	5950	Concesiones	
11181	5960	Franquicias	
11182	5970	Licencias informaticas e intelectuales	
11183	5980	Licencias industriales, comerciales y otras	
11184	5990	Otros activos intangibles	
11185	6000	Inversion publica	
11186	6100	Obra publica en bienes de dominio publico	
11187	6110	Edificacion habitacional	
11188	61100101	Construccion de casa habitacion	Obra
11189	61100102	Construccion de vivienda multifamiliar	Obra
11190	61100103	Construccion de vivienda unifamiliar	Obra
11191	61100104	Estudios de preinversion y/o preparacion del proyecto para vivienda multifamiliar	Obra
11192	61100105	Estudios de preinversion y/o preparacion del proyecto para vivienda unifamiliar	Obra
11193	61100201	Ampliacion de vivienda multifamiliar	Obra
11194	61100202	Ampliacion de vivienda unifamiliar	Obra
11195	61100203	Remodelacion de vivienda multifamiliar	Obra
11196	61100204	Remodelacion de vivienda unifamiliar	Obra
11197	61100205	Mantenimiento de vivienda multifamiliar	Obra
11198	61100206	Mantenimiento de vivienda unifamiliar	Obra
11199	6120	Edificacion no habitacional	
11200	61200101	Construccion de almacen	Obra
11201	61200102	Construccion de almacenes y edificios industriales	Obra
11202	61200103	Construccion de clinica o centro de salud	Obra
11203	61200104	Construccion de edificio	Obra
11204	61200105	Construccion de edificios comerciales	Obra
11205	61200106	Construccion de edificios de entretenimiento publico	Obra
11206	61200107	Construccion de edificios de multiples viviendas	Obra
11207	61200108	Construccion de edificios de salud	Obra
11208	61200109	Construccion de edificios de una y dos viviendas	Obra
11209	61200110	Construccion de edificios educativos	Obra
11210	61200111	Construccion de escuela	Obra
11211	61200112	Construccion de hospital	Obra
11212	61200113	Construccion de hoteles, restaurantes y edificios similares	Obra
11213	61200114	Construccion de otros edificios	Obra
11214	61200115	Construccion de taller	Obra
11215	61200116	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio de una vivienda, dos o multiples viviendas no habitacional	Obra
11216	61200117	Estudios de preinversion y/o preparacion del proyecto para construccion de almacen	Obra
11217	61200118	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio industrial	Obra
11218	61200119	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio comercial	Obra
11219	61200120	Estudios de preinversion y/o preparacion del proyecto para construccion de entretenimiento publico	Obra
11220	61200121	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio educativo	Obra
11221	61200122	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio de salud	Obra
11222	61200123	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio administrativo	Obra
11223	61200201	Conservacion y/o mantenimiento de edificios de una, dos o multiples viviendas no habitacional	Obra
11224	61200202	Conservacion y/o mantenimiento de almacen	Obra
11225	61200203	Conservacion y/o mantenimiento de edificio industrial	Obra
11226	61200204	Conservacion y/o mantenimiento de edificio comercial	Obra
11227	61200205	Conservacion y/o mantenimiento de edificio de entretenimiento publico	Obra
11228	61200206	Conservacion y/o mantenimiento de edificio educativo	Obra
11229	61200207	Conservacion y/o mantenimiento de escuela	Obra
11230	61200208	Conservacion y/o mantenimiento de edificio de salud	Obra
11231	61200209	Conservacion y/o mantenimiento de hospital	Obra
11232	61200210	Conservacion y/o mantenimiento de edificio administrativo	Obra
11233	61200211	Rehabilitacion de edificio de una, dos o multiples viviendas no habitacional	Obra
11234	61200212	Rehabilitacion de almacen	Obra
11235	61200213	Rehabilitacion de edificio industrial	Obra
11236	61200214	Rehabilitacion de edificio comercial	Obra
11237	61200215	Rehabilitacion de edificio de entretenimiento publico	Obra
11238	61200216	Rehabilitacion de edificio educativo	Obra
11239	61200217	Rehabilitacion de escuela	Obra
11240	61200218	Rehabilitacion de edificio de salud	Obra
11241	61200219	Rehabilitacion de hospital	Obra
11242	61200220	Rehabilitacion de edificio administrativo	Obra
11243	61200221	Remozamiento de edificio de una, dos o multiples viviendas no habitacional	Obra
11244	61200222	Remozamiento de almacen	Obra
11245	61200223	Remozamiento de edificio industrial	Obra
11246	61200224	Remozamiento de edificio comercial	Obra
11247	61200225	Remozamiento de edificio de entretenimiento publico	Obra
11248	61200226	Remozamiento de edificio educativo	Obra
11249	61200227	Remozamiento de escuela	Obra
11250	61200228	Remozamiento de edificio de salud	Obra
11251	61200229	Remozamiento de hospital	Obra
11252	61200230	Remozamiento de edificio administrativo	Obra
11253	61200231	Ampliacion de edificio de una, dos o multiples viviendas no habitacional	Obra
11254	61200232	Ampliacion de almacen	Obra
11255	61200233	Ampliacion de edificio industrial	Obra
11256	61200234	Ampliacion de edificio comercial	Obra
11257	61200235	Ampliacion de edificio de entretenimiento publico	Obra
11258	61200236	Ampliacion de edificio educativo	Obra
11259	61200237	Ampliacion de escuela	Obra
11260	61200238	Ampliacion de edificio de salud	Obra
11261	61200239	Ampliacion de hospital	Obra
11262	61200240	Ampliacion de edificio administrativo	Obra
11263	61200241	Reparacion integral  de edificio de una, dos o multiples viviendas no habitacional	Obra
11264	61200242	Reparacion integral  de almacen	Obra
11265	61200243	Reparacion integral  de edificio industrial	Obra
11266	61200244	Reparacion integral  de edificio comercial	Obra
11267	61200245	Reparacion integral  de edificio de entretenimiento publico	Obra
11268	61200246	Reparacion integral  de edificio educativo	Obra
11269	61200247	Reparacion integral  de escuela	Obra
11270	61200248	Reparacion integral  de edificio de salud	Obra
11271	61200249	Reparacion integral  de hospital	Obra
11272	61200250	Reparacion integral  de edificio administrativo	Obra
11273	6130	Construccion de obras para el abastecimiento de agua, petroleo, gas, electricidad y telecomunicaciones	
11274	61300101	Construccion de obra para el abastecimiento de agua	Obra
11275	61300102	Construccion de obra para el abastecimiento de gas	Obra
11276	61300103	Construccion de obra para el abastecimiento de petroleo	Obra
11277	61300104	Construccion de obra para la generacion de energia electrica	Obra
11278	61300105	Construccion de obra para las telecomunicaciones	Obra
11279	61300106	Estudios de preinversion y/o preparacion del proyecto para el abastecimiento de agua	Obra
11280	61300107	Estudios de preinversion y/o preparacion del proyecto para el abastecimiento de gas	Obra
11281	61300108	Estudios de preinversion y/o preparacion del proyecto para el abastecimiento de petroleo	Obra
11282	61300109	Estudios de preinversion y/o preparacion del proyecto para la generacion de energia electrica	Obra
11283	61300110	Estudios de preinversion y/o preparacion del proyecto para las telecomunicaciones	Obra
11284	61300201	Conservacion y/o mantenimiento de obra para el abastecimiento de agua	Obra
11285	61300202	Conservacion y/o mantenimiento de obra para el abastecimiento de gas	Obra
11286	61300203	Conservacion y/o mantenimiento de obra para el abastecimiento de petroleo	Obra
11287	61300204	Conservacion y/o mantenimiento de obra para la generacion de energia electrica	Obra
11288	61300205	Conservacion y/o mantenimiento de obra para las telecomunicaciones	Obra
11289	61300206	Rehabilitacion de obra para el abastecimiento de agua	Obra
11290	61300207	Rehabilitacion de obra para el abastecimiento de gas	Obra
11291	61300208	Rehabilitacion de obra para el abastecimiento de petroleo	Obra
11292	61300209	Rehabilitacion de obra para la generacion de energia electrica	Obra
11293	61300210	Rehabilitacion de obra para las telecomunicaciones	Obra
11294	61300211	Remozamiento de obra para el abastecimiento de agua	Obra
11295	61300212	Remozamiento de obra para el abastecimiento de gas	Obra
11296	61300213	Remozamiento de obra para el abastecimiento de petroleo	Obra
11297	61300214	Remozamiento de obra para la generacion de energia electrica	Obra
11298	61300215	Remozamiento de obra para las telecomunicaciones	Obra
11299	61300216	Ampliacion de obra para el abastecimiento de agua	Obra
11300	61300217	Ampliacion de obra para el abastecimiento de gas	Obra
11301	61300218	Ampliacion de obra para el abastecimiento de petroleo	Obra
11302	61300219	Ampliacion de obra para la generacion de energia electrica	Obra
11303	61300220	Ampliacion de obra para las telecomunicaciones	Obra
11304	61300221	Reparacion integral de obra para el abastecimiento de agua	Obra
11305	61300222	Reparacion integral de obra para el abastecimiento de gas	Obra
11306	61300223	Reparacion integral de obra para el abastecimiento de petroleo	Obra
11307	61300224	Reparacion integral de obra para la generacion de energia electrica	Obra
11308	61300225	Reparacion integral de obra para las telecomunicaciones	Obra
11309	6140	Division de terrenos y construccion de obras de urbanizacion	
11310	61400101	Demolicion de almacen	Obra
11311	61400102	Demolicion de camino	Obra
11312	61400103	Demolicion de canal	Obra
11313	61400104	Demolicion de carretera	Obra
11314	61400105	Demolicion de casa habitacion	Obra
11315	61400106	Demolicion de clinica o centro de salud	Obra
11316	61400107	Demolicion de edificio	Obra
11317	61400108	Demolicion de escollera	Obra
11318	61400109	Demolicion de escuela	Obra
11319	61400110	Demolicion de hospital	Obra
11320	61400111	Demolicion de linea de transmision	Obra
11321	61400112	Demolicion de malecon	Obra
11322	61400113	Demolicion de muelle	Obra
11323	61400114	Demolicion de obra de agua potable	Obra
11324	61400115	Demolicion de obra de alumbrado	Obra
11325	61400116	Demolicion de obra de drenaje	Obra
11326	61400117	Demolicion de obra de electrificacion	Obra
11327	61400118	Demolicion de obra de irrigacion	Obra
11328	61400119	Demolicion de obra de pavimentacion	Obra
11329	61400120	Demolicion de obra de telefonia	Obra
11330	61400121	Demolicion de planta de tratamiento de agua potable	Obra
11331	61400122	Demolicion de planta de tratamiento de aguas residuales	Obra
11332	61400123	Demolicion de planta de tratamiento de gas	Obra
11333	61400124	Demolicion de planta geoelectrica	Obra
11334	61400125	Demolicion de planta hidroelectrica	Obra
11335	61400126	Demolicion de planta nucleoelectrica	Obra
11336	61400127	Demolicion de planta petroquimica	Obra
11337	61400128	Demolicion de planta termoelectrica	Obra
11338	61400129	Demolicion de presa	Obra
11339	61400130	Demolicion de puente	Obra
11340	61400131	Demolicion de red de distribucion	Obra
11341	61400132	Demolicion de refineria	Obra
11342	61400133	Demolicion de taller	Obra
11343	61400134	Demolicion de terminal de almacenamiento y distribucion	Obra
11344	61400135	Obras de andamiaje	Obra
11345	61400136	Obras de demolicion	Obra
11346	61400137	Obras de excavacion y remocion de tierra	Obra
11347	61400138	Obras de investigacion de campo	Obra
11348	61400139	Obras de limpieza y preparacion de terreno	Obra
11349	61400140	Obras de preparacion de terreno para mineria (excepto extraccion de petroleo y gas)	Obra
11350	61400201	Construccion de banquetas	Obra
11351	61400202	Construccion de guarniciones	Obra
11352	61400203	Construccion de red de agua potable	Obra
11353	61400204	Construccion de red de alcantarillado	Obra
11354	61400205	Construccion de red de energia	Obra
11355	61400206	Estudios de preinversion y/o preparacion del proyecto para banquetas	Obra
11356	61400207	Estudios de preinversion y/o preparacion del proyecto para guarniciones	Obra
11357	61400208	Estudios de preinversion y/o preparacion del proyecto para red de agua potable	Obra
11358	61400209	Estudios de preinversion y/o preparacion del proyecto para red de alcantarillado	Obra
11359	61400210	Estudios de preinversion y/o preparacion del proyecto para red de energia	Obra
11360	61400301	Conservacion y/o mantenimiento de banquetas	Obra
11361	61400302	Conservacion y/o mantenimiento de guarniciones	Obra
11362	61400303	Conservacion y/o mantenimiento de red de agua potable	Obra
11363	61400304	Conservacion y/o mantenimiento de red de alcantarillado	Obra
11364	61400305	Conservacion y/o mantenimiento de red de energia	Obra
11365	61400306	Rehabilitacion de banquetas	Obra
11366	61400307	Rehabilitacion de guarniciones	Obra
11367	61400308	Rehabilitacion de red de agua potable	Obra
11368	61400309	Rehabilitacion de red de alcantarillado	Obra
11369	61400310	Rehabilitacion de red de energia	Obra
11370	61400311	Remozamiento de banquetas	Obra
11371	61400312	Remozamiento de guarniciones	Obra
11372	61400313	Remozamiento de red de agua potable	Obra
11373	61400314	Remozamiento de red de alcantarillado	Obra
11374	61400315	Remozamiento de red de energia	Obra
11375	61400316	Ampliacion de banquetas	Obra
11376	61400317	Ampliacion de guarniciones	Obra
11377	61400318	Ampliacion de red de agua potable	Obra
11378	61400319	Ampliacion de red de alcantarillado	Obra
11379	61400320	Ampliacion de red de energia	Obra
11380	61400321	Reparacion integral de banquetas	Obra
11381	61400322	Reparacion integral de guarniciones	Obra
11382	61400323	Reparacion integral de red de agua potable	Obra
11383	61400324	Reparacion integral de red de alcantarillado	Obra
11384	61400325	Reparacion integral de red de energia	Obra
11385	6150	Construccion de vias de comunicacion	
11386	61500101	Construccion aeropista	Obra
11387	61500102	Construccion autopista	Obra
11388	61500103	Construccion carretera	Obra
11389	61500104	Construccion de camino	Obra
11390	61500105	Construccion de pasos a desnivel	Obra
11391	61500106	Construccion de puente	Obra
11392	61500107	Construccion de terraceria	Obra
11393	61500108	Estudios de preinversion y/o preparacion del proyecto para aeropista	Obra
11394	61500109	Estudios de preinversion y/o preparacion del proyecto para autopista	Obra
11395	61500110	Estudios de preinversion y/o preparacion del proyecto para carretera	Obra
11396	61500111	Estudios de preinversion y/o preparacion del proyecto para pasos a desnivel	Obra
11397	61500112	Estudios de preinversion y/o preparacion del proyecto para puente	Obra
11398	61500113	Estudios de preinversion y/o preparacion del proyecto para terraceria	Obra
11399	61500201	Conservacion y/o mantenimiento de aeropista	Obra
11400	61500202	Conservacion y/o mantenimiento de autopista	Obra
11401	61500203	Conservacion y/o mantenimiento pasos a desnivel	Obra
11402	61500204	Conservacion y/o mantenimiento de puente	Obra
11403	61500205	Conservacion y/o mantenimiento de terraceria	Obra
11404	61500206	Rehabilitacion de aeropista	Obra
11405	61500207	Rehabilitacion de autopista	Obra
11406	61500208	Rehabilitacion pasos a desnivel	Obra
11407	61500209	Rehabilitacion de puente	Obra
11408	61500210	Rehabilitacion de terraceria	Obra
11409	61500211	Remozamiento de aeropista	Obra
11410	61500212	Remozamiento de autopista	Obra
11411	61500213	Remozamiento pasos a desnivel	Obra
11412	61500214	Remozamiento de puente	Obra
11413	61500215	Remozamiento de terraceria	Obra
11414	61500216	Ampliacion de aeropista	Obra
11415	61500217	Ampliacion de autopista	Obra
11416	61500218	Ampliacion pasos a desnivel	Obra
11417	61500219	Ampliacion de puente	Obra
11418	61500220	Ampliacion de terraceria	Obra
11419	61500221	Reparacion integral de aeropista	Obra
11420	61500222	Reparacion integral de autopista	Obra
11421	61500223	Reparacion integral pasos a desnivel	Obra
11422	61500224	Reparacion integral de puente	Obra
11423	61500225	Reparacion integral de terraceria	Obra
11424	6160	Otras construcciones de ingenieria civil u obra pesada	
11425	61600101	Construccion de presa y/o represa	Obra
11426	61600102	Construccion de obra maritima	Obra
11427	61600103	Construccion de obra fluvial	Obra
11428	61600104	Construccion de obra subacuatica	Obra
11429	61600105	Construccion de obra para el transporte electrico	Obra
11430	61600106	Construccion de obra para el transporte ferroviario	Obra
11431	61600107	Otra construccion de ingenieria civil	Obra
11432	61600108	Otra construccion de obra pesada	Obra
11433	61600109	Construccion de canal	Obra
11434	61600110	Construccion de carretera elevada (puente)	Obra
11435	61600111	Construccion de obra para mineria	Obra
11436	61600112	Estudios de preinversion y/o preparacion del proyecto para obra de construccion de presa y/o represa	Obra
11437	61600113	Estudios de preinversion y/o preparacion del proyecto para obra de construccion fluvial	Obra
11438	61600114	Estudios de preinversion y/o preparacion del proyecto para obra de construccion maritima	Obra
11439	61600115	Estudios de preinversion y/o preparacion del proyecto para obra de construccion para transporte electrico	Obra
11440	61600116	Estudios de preinversion y/o preparacion del proyecto para obra de construccion para transporte ferroviario	Obra
11441	61600117	Estudios de preinversion y/o preparacion del proyecto para obra de construccion subacuatica	Obra
11442	61600118	Estudios de preinversion y/o preparacion del proyecto para otra construccion de ingenieria civil	Obra
11443	61600119	Estudios de preinversion y/o preparacion del proyecto para otra construccion de obra pesada	Obra
11444	61600201	Conservacion y/o mantenimiento de presa y/o represa	Obra
11445	61600202	Conservacion y/o mantenimiento de obra maritima	Obra
11446	61600203	Conservacion y/o mantenimiento de obra fluvial	Obra
11447	61600204	Conservacion y/o mantenimiento de obra subacuatica	Obra
11448	61600205	Conservacion y/o mantenimiento de obra para el transporte electrico	Obra
11449	61600206	Conservacion y/o mantenimiento de obra para el transporte ferroviario	Obra
11450	61600207	Conservacion y/o mantenimiento de otra obra de ingenieria civil	Obra
11451	61600208	Conservacion y/o mantenimiento de otra obra de construccion pesada	Obra
11452	61600209	Rehabilitacion de presa y/o represa	Obra
11453	61600210	Rehabilitacion de obra maritima	Obra
11454	61600211	Rehabilitacion de obra fluvial	Obra
11455	61600212	Rehabilitacion de obra subacuatica	Obra
11456	61600213	Rehabilitacion de obra para el transporte electrico	Obra
11457	61600214	Rehabilitacion de obra para el transporte ferroviario	Obra
11458	61600215	Rehabilitacion de otra obra de ingenieria civil	Obra
11459	61600216	Rehabilitacion de otra obra de construccion pesada	Obra
11460	61600217	Remozamiento de presa y/o represa	Obra
11461	61600218	Remozamiento de obra maritima	Obra
11462	61600219	Remozamiento de obra fluvial	Obra
11463	61600220	Remozamiento de obra subacuatica	Obra
11464	61600221	Remozamiento de obra para el transporte electrico	Obra
11465	61600222	Remozamiento de obra para el transporte ferroviario	Obra
11466	61600223	Remozamiento otra obra de ingenieria civil	Obra
11467	61600224	Remozamiento de otra obra de construccion pesada	Obra
11468	61600225	Ampliacion de presa y/o represa	Obra
11469	61600226	Ampliacion de obra maritima	Obra
11470	61600227	Ampliacion de obra fluvial	Obra
11471	61600228	Ampliacion de obra subacuatica	Obra
11472	61600229	Ampliacion de obra para el transporte electrico	Obra
11473	61600230	Ampliacion de obra para el transporte ferroviario	Obra
11474	61600231	Ampliacion de otra obra de ingenieria civil	Obra
11475	61600232	Ampliacion de otra obra de construccion pesada	Obra
11476	61600233	Reparacion integral de presa y/o represa	Obra
11477	61600234	Reparacion integral de obra maritima	Obra
11478	61600235	Reparacion integral de obra fluvial	Obra
11479	61600236	Reparacion integral de obra subacuatica	Obra
11480	61600237	Reparacion integral de obra para el transporte electrico	Obra
11481	61600238	Reparacion integral de obra para el transporte ferroviario	Obra
11482	61600239	Reparacion integral de otra obra de ingenieria civil	Obra
11483	61600240	Reparacion integral de otra obra de construccion pesada	Obra
11484	61600241	Dragado en canal	Obra
11485	61600242	Dragado en presa	Obra
11486	61600243	Dragado fluvial	Obra
11487	61600244	Dragado lacustre	Obra
11488	61600245	Dragado maritimo	Obra
11489	6170	Instalaciones y equipamiento en construcciones	
11490	61700101	Construccion de escollera	Obra
11491	61700102	Construccion de gasoducto	Obra
11492	61700103	Construccion de gasolinoducto	Obra
11493	61700104	Construccion de linea de transmision	Obra
11494	61700105	Construccion de malecon	Obra
11495	61700106	Construccion de muelle	Obra
11496	61700107	Construccion de obra de agua potable	Obra
11497	61700108	Construccion de obra de alumbrado	Obra
11498	61700109	Construccion de obra de drenaje	Obra
11499	61700110	Construccion de obra de electrificacion	Obra
11500	61700111	Construccion de obra de irrigacion	Obra
11501	61700112	Construccion de obra de pavimentacion	Obra
11502	61700113	Construccion de obra de telefonia	Obra
11503	61700114	Construccion de oleoducto	Obra
11504	61700115	Construccion de planta de tratamiento de agua potable	Obra
11505	61700116	Construccion de planta de tratamiento de aguas residuales	Obra
11506	61700117	Construccion de planta de tratamiento de gas	Obra
11507	61700118	Construccion de planta geoelectrica	Obra
11508	61700119	Construccion de planta hidroelectrica	Obra
11509	61700120	Construccion de planta nucleoelectrica	Obra
11510	61700121	Construccion de planta petroquimica	Obra
11511	61700122	Construccion de planta termoelectrica	Obra
11512	61700123	Construccion de poliducto	Obra
11513	61700124	Construccion de presa	Obra
11514	61700125	Construccion de red de distribucion	Obra
11515	61700126	Construccion de refineria	Obra
11516	61700127	Construccion de terminal de almacenamiento y distribucion	Obra
11517	61700128	Maniobras con grua	Obra
11518	61700129	Obra de construccion de enrejados y pasamanos	Obra
11519	61700130	Obras de aislamiento (cableado electrico, agua, calefaccion, sonido)	Obra
11520	61700131	Obras de albañileria	Obra
11521	61700132	Obras de calefaccion, ventilacion o aire acondicionado	Obra
11522	61700133	Obras de doblaje y edificacion de acero, incluye soldadura.	Obra
11523	61700134	Obras de edificacion incluyendo la instalacion de pilotes	Obra
11524	61700135	Obras de instalacion de pilotes	Obra
11525	61700136	Obras de perforacion de pozos	Obra
11526	61700137	Obras de perforacion de pozos de agua	Obra
11527	61700138	Obras de plomeria hidraulica o de tendido de drenaje	Obra
11528	61700139	Obras de techado e impermeabilizacion	Obra
11529	61700140	Obras de tendido de concreto.	Obra
11530	61700141	Obras electricas	Obra
11531	61700142	Obras para la construccion de conexiones de gas	Obra
11532	61700143	Perforacion de pozo de exploracion en mar	Obra
11533	61700144	Perforacion de pozo de exploracion en tierra	Obra
11534	61700145	Perforacion de pozo de produccion en mar	Obra
11535	61700146	Perforacion de pozo de produccion en tierra	Obra
11536	61700147	Reconfiguracion de planta de tratamiento de gas	Obra
11537	61700148	Reconfiguracion de planta petroquimica	Obra
11538	61700149	Reconfiguracion de refineria	Obra
11539	61700150	Recuperacion de ductos	Obra
11540	61700151	Reparacion de pozo de produccion	Obra
11541	61700152	Estudios de preinversion y/o preparacion del proyecto para instalacion de aire acondicionado	Obra
11542	61700153	Estudios de preinversion y/o preparacion del proyecto para instalacion de calefaccion	Obra
11543	61700154	Estudios de preinversion y/o preparacion del proyecto para instalacion de suministro de gas	Obra
11544	61700155	Estudios de preinversion y/o preparacion del proyecto para instalacion electrica	Obra
11545	61700156	Estudios de preinversion y/o preparacion del proyecto para instalacion en obra no clasificada	Obra
11546	61700157	Estudios de preinversion y/o preparacion del proyecto para instalacion hidrosanitaria	Obra
11547	61700158	Estudios de preinversion y/o preparacion del proyecto para instalacion electromecanica	Obra
11548	6190	Trabajos de acabados en edificaciones y otros trabajos especializados	
11549	61900101	Obra de ensamble y/o edificacion de construccion prefabricada	Obra
11550	61900201	Colocacion de azulejos	Obra
11551	61900202	Embaldosado y/o colocacion de pisos	Obra
11552	61900203	Instalacion de canceleria en inmueble	Obra
11553	61900204	Instalacion de productos de carpinteria en inmuebles	Obra
11554	61900205	Instalacion de productos metalicos en inmuebles	Obra
11555	61900206	Instalacion de ventanas	Obra
11556	61900207	Obra de decoracion y/o ornamentacion de inmueble	Obra
11557	61900208	Obra de ornamentacion	Obra
11558	61900209	Obras de decoracion de interiores	Obra
11559	61900210	Obras de embaldosado de pisos y colocacion de azulejos en paredes	Obra
11560	61900211	Obras de enyesado	Obra
11561	61900212	Obras de pintado	Obra
11562	61900213	Obras de sellado e instalacion de ventanas	Obra
11563	61900214	Obras en madera o metal y carpinteria	Obra
11564	61900215	Tapizado de inmueble	Obra
11565	61900301	Supervision de obras publicas	Obra
11566	61900401	Servicios para la liberacion de derechos de via	Obra
11567	61900501	Arrendamientos relacionados con equipos para la construccion, demolicion de edificios u obras de ingenieria civil	Obra
11568	61900502	Diseño arquitectonico	Obra
11569	61900503	Diseño artistico para obra publica	Obra
11570	61900504	Diseño de ingenieria electromecanica para obra publica	Obra
11571	61900505	Diseño de ingenieria industrial para obra publica	Obra
11572	61900506	Estudio de aerofotogrametria	Obra
11573	61900507	Estudio de control de calidad para obra publica	Obra
11574	61900508	Estudio de geofisica	Obra
11575	61900509	Estudio de geologia	Obra
11576	61900510	Estudio de geotermia	Obra
11577	61900511	Estudio de hidrologia para obra publica	Obra
11578	61900512	Estudio de impacto ambiental para obra publica	Obra
11579	61900513	Estudio de informatica y sistemas para obra publica	Obra
11580	61900514	Estudio de ingenieria de transito para obra publica	Obra
11581	61900515	Estudio de mecanica del suelo para obra publica	Obra
11582	61900516	Estudio de oceonografia y/o meteorologia	Obra
11583	61900517	Estudio de radiografia industrial para obra publica	Obra
11584	61900518	Estudio de resistencia de materiales para obra publica	Obra
11585	61900519	Estudio de restitucion de la eficiencia de las instalaciones para obra publica	Obra
11586	61900520	Estudio de trabajo de organizacion para obra publica	Obra
11587	61900521	Estudio ecologico y de impacto ambiental	Obra
11588	61900522	Estudio tecnico de agronomia y desarrollo pecuario para obra publica	Obra
11589	61900523	Estudio tecnico relacionados con obra publica	Obra
11590	61900524	Estudio topografico	Obra
11591	61900525	Estudios de tenencia de la tierra	Obra
11592	61900526	Servicios de apoyo a la calidad del agua	Obra
11593	61900527	Servicios de apoyo a la calidad del aire	Obra
11594	61900528	Servicios de dragado	Obra
11595	61900529	Servicios de topografia	Obra
11596	61900530	Estudios de preinversion y/o preparacion del proyecto para alquiler de maquinaria y/o equipo para construccion con operador	Obra
11597	61900531	Estudios de preinversion y/o preparacion del proyecto para aplicacion de cubrimientos en inmuebles	Obra
11598	61900532	Estudios de preinversion y/o preparacion del proyecto para aplicacion de pintura en inmuebles	Obra
11599	61900533	Estudios de preinversion y/o preparacion del proyecto para colocacion de muros	Obra
11600	61900534	Estudios de preinversion y/o preparacion del proyecto para colocacion de pisos y/o azulejos	Obra
11601	61900535	Estudios de preinversion y/o preparacion del proyecto para demolicion de edificaciones	Obra
11602	61900536	Estudios de preinversion y/o preparacion del proyecto para demolicion de estructuras	Obra
11603	61900537	Estudios de preinversion y/o preparacion del proyecto para enyesado de inmuebles	Obra
11604	62202027	Remozamiento de escuela	Servicio de Obra Publica
11605	61900538	Estudios de preinversion y/o preparacion del proyecto para excavacion de terreno	Obra
11606	61900539	Estudios de preinversion y/o preparacion del proyecto para impermeabilizacion de inmuebles	Obra
11607	61900540	Estudios de preinversion y/o preparacion del proyecto para instalacion de canceleria en inmuebles	Obra
11608	61900541	Estudios de preinversion y/o preparacion del proyecto para instalacion de productos de carpinteria en inmuebles	Obra
11609	61900542	Estudios de preinversion y/o preparacion del proyecto para preparacion de terreno para construccion	Obra
11610	6200	Obra publica en bienes propios	
11611	6210	Edificacion habitacional	
11612	62101	Obras de construccion para edificios habitacionales	
11613	62101001	Construccion de casa habitacion	Obra
11614	62101002	Construccion de vivienda multifamiliar	Obra
11615	62101003	Construccion de vivienda unifamiliar	Obra
11616	62101004	Estudios de preinversion y/o preparacion del proyecto para vivienda multifamiliar	Obra
11617	62101005	Estudios de preinversion y/o preparacion del proyecto para vivienda unifamiliar	Obra
11618	62102	Mantenimiento y rehabilitacon de edificaciones habitacionales	
11619	62102001	Ampliacion de vivienda multifamiliar	Servicio de Obra Publica
11620	62102002	Ampliacion de vivienda unifamiliar	Servicio de Obra Publica
11621	62102003	Remodelacion de vivienda multifamiliar	Servicio de Obra Publica
11622	62102004	Remodelacion de vivienda unifamiliar	Servicio de Obra Publica
11623	62102005	Mantenimiento de vivienda multifamiliar	Servicio de Obra Publica
11624	62102006	Mantenimiento de vivienda unifamiliar	Servicio de Obra Publica
11625	6220	Edificacion no habitacional	
11626	62201	Obras de construccion para edificios no habitacionales	
11627	62201001	Construccion de almacen	Obra
11628	62201002	Construccion de almacenes y edificios industriales	Obra
11629	62201003	Construccion de clinica o centro de salud	Obra
11630	62201004	Construccion de edificio	Obra
11631	62201005	Construccion de edificios comerciales	Obra
11632	62201006	Construccion de edificios de entretenimiento publico	Obra
11633	62201007	Construccion de edificios de multiples viviendas	Obra
11634	62201008	Construccion de edificios de salud	Obra
11635	62201009	Construccion de edificios de una y dos viviendas	Obra
11636	62201010	Construccion de edificios educativos	Obra
11637	62201011	Construccion de escuela	Obra
11638	62201012	Construccion de hospital	Obra
11639	62201013	Construccion de hoteles, restaurantes y edificios similares	Obra
11640	62201014	Construccion de otros edificios	Obra
11641	62201015	Construccion de taller	Obra
11642	62201016	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio de una vivienda, dos o multiples viviendas no habitacional	Obra
11643	62201017	Estudios de preinversion y/o preparacion del proyecto para construccion de almacen	Obra
11644	62201018	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio industrial	Obra
11645	62201019	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio comercial	Obra
11646	62201020	Estudios de preinversion y/o preparacion del proyecto para construccion de entretenimiento publico	Obra
11647	62201021	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio educativo	Obra
11648	62201022	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio de salud	Obra
11649	62201023	Estudios de preinversion y/o preparacion del proyecto para construccion de edificio administrativo	Obra
11650	62201024	Construccion de instalaciones deportivas	Obra
11651	62202	Mantenimiento y rehabilitacion de edificaciones no habitacionales	
11652	62202001	Conservacion y/o mantenimiento de edificios de una, dos o multiples viviendas no habitacional	Servicio de Obra Publica
11653	62202002	Conservacion y/o mantenimiento de almacen	Servicio de Obra Publica
11654	62202003	Conservacion y/o mantenimiento de edificio industrial	Servicio de Obra Publica
11655	62202004	Conservacion y/o mantenimiento de edificio comercial	Servicio de Obra Publica
11656	62202005	Conservacion y/o mantenimiento de edificio de entretenimiento publico	Servicio de Obra Publica
11657	62202006	Conservacion y/o mantenimiento de edificio educativo	Servicio de Obra Publica
11658	62202007	Conservacion y/o mantenimiento de escuela	Servicio de Obra Publica
11659	62202008	Conservacion y/o mantenimiento de edificio de salud	Servicio de Obra Publica
11660	62202009	Conservacion y/o mantenimiento de hospital	Servicio de Obra Publica
11661	62202010	Conservacion y/o mantenimiento de edificio administrativo	Servicio de Obra Publica
11662	62202011	Rehabilitacion de edificio de una, dos o multiples viviendas no habitacional	Servicio de Obra Publica
11663	62202012	Rehabilitacion de almacen	Servicio de Obra Publica
11664	62202013	Rehabilitacion de edificio industrial	Servicio de Obra Publica
11665	62202014	Rehabilitacion de edificio comercial	Servicio de Obra Publica
11666	62202015	Rehabilitacion de edificio de entretenimiento publico	Servicio de Obra Publica
11667	62202016	Rehabilitacion de edificio educativo	Servicio de Obra Publica
11668	62202017	Rehabilitacion de escuela	Servicio de Obra Publica
11669	62202018	Rehabilitacion de edificio de salud	Servicio de Obra Publica
11670	62202019	Rehabilitacion de hospital	Servicio de Obra Publica
11671	62202020	Rehabilitacion de edificio administrativo	Servicio de Obra Publica
11672	62202021	Remozamiento de edificio de una, dos o multiples viviendas no habitacional	Servicio de Obra Publica
11673	62202022	Remozamiento de almacen	Servicio de Obra Publica
11674	62202023	Remozamiento de edificio industrial	Servicio de Obra Publica
11675	62202024	Remozamiento de edificio comercial	Servicio de Obra Publica
11676	62202025	Remozamiento de edificio de entretenimiento publico	Servicio de Obra Publica
11677	62202026	Remozamiento de edificio educativo	Servicio de Obra Publica
11678	62202028	Remozamiento de edificio de salud	Servicio de Obra Publica
11679	62202029	Remozamiento de hospital	Servicio de Obra Publica
11680	62202030	Remozamiento de edificio administrativo	Servicio de Obra Publica
11681	62202031	Ampliacion de edificio de una, dos o multiples viviendas no habitacional	Servicio de Obra Publica
11682	62202032	Ampliacion de almacen	Servicio de Obra Publica
11683	62202033	Ampliacion de edificio industrial	Servicio de Obra Publica
11684	62202034	Ampliacion de edificio comercial	Servicio de Obra Publica
11685	62202035	Ampliacion de edificio de entretenimiento publico	Servicio de Obra Publica
11686	62202036	Ampliacion de edificio educativo	Servicio de Obra Publica
11687	62202037	Ampliacion de escuela	Servicio de Obra Publica
11688	62202038	Ampliacion de edificio de salud	Servicio de Obra Publica
11689	62202039	Ampliacion de hospital	Servicio de Obra Publica
11690	62202040	Ampliacion de edificio administrativo	Servicio de Obra Publica
11691	62202041	Reparacion integral  de edificio de una, dos o multiples viviendas no habitacional	Servicio de Obra Publica
11692	62202042	Reparacion integral  de almacen	Servicio de Obra Publica
11693	62202043	Reparacion integral  de edificio industrial	Servicio de Obra Publica
11694	62202044	Reparacion integral  de edificio comercial	Servicio de Obra Publica
11695	62401032	Demolicion de refineria	Obra
11696	62202045	Reparacion integral  de edificio de entretenimiento publico	Servicio de Obra Publica
11697	62202046	Reparacion integral  de edificio educativo	Servicio de Obra Publica
11698	62202047	Reparacion integral  de escuela	Servicio de Obra Publica
11699	62202048	Reparacion integral  de edificio de salud	Servicio de Obra Publica
11700	62202049	Reparacion integral  de hospital	Servicio de Obra Publica
11701	62202050	Reparacion integral  de edificio administrativo	Servicio de Obra Publica
11702	6230	Construccion de obras para el abastecimiento de agua, petroleo, gas, electricidad y telecomunicaciones	
11703	62301	Construccion de obras para el abastecimiento de agua, petroleo, gas, electricidad y telecomunicaciones	
11704	62301001	Construccion de obra para el abastecimiento de agua	Obra
11705	62301002	Construccion de obra para el abastecimiento de gas	Obra
11706	62301003	Construccion de obra para el abastecimiento de petroleo	Obra
11707	62301004	Construccion de obra para la generacion de energia electrica	Obra
11708	62301005	Construccion de obra para las telecomunicaciones	Obra
11709	62301006	Estudios de preinversion y/o preparacion del proyecto para el abastecimiento de agua	Obra
11710	62301007	Estudios de preinversion y/o preparacion del proyecto para el abastecimiento de gas	Obra
11711	62301008	Estudios de preinversion y/o preparacion del proyecto para el abastecimiento de petroleo	Obra
11712	62301009	Estudios de preinversion y/o preparacion del proyecto para la generacion de energia electrica	Obra
11713	62301010	Estudios de preinversion y/o preparacion del proyecto para las telecomunicaciones	Obra
11714	62302	Mantenimiento y rehabilitacion de obras para el abastecimiento de agua, petroleo, gas, electricidad y telecomunicaciones	
11715	62302001	Conservacion y/o mantenimiento de obra para el abastecimiento de agua	Servicio de Obra Publica
11716	62302002	Conservacion y/o mantenimiento de obra para el abastecimiento de gas	Servicio de Obra Publica
11717	62302003	Conservacion y/o mantenimiento de obra para el abastecimiento de petroleo	Servicio de Obra Publica
11718	62302004	Conservacion y/o mantenimiento de obra para la generacion de energia electrica	Servicio de Obra Publica
11719	62302005	Conservacion y/o mantenimiento de obra para las telecomunicaciones	Servicio de Obra Publica
11720	62302006	Rehabilitacion de obra para el abastecimiento de agua	Servicio de Obra Publica
11721	62302007	Rehabilitacion de obra para el abastecimiento de gas	Servicio de Obra Publica
11722	62302008	Rehabilitacion de obra para el abastecimiento de petroleo	Servicio de Obra Publica
11723	62302009	Rehabilitacion de obra para la generacion de energia electrica	Servicio de Obra Publica
11724	62302010	Rehabilitacion de obra para las telecomunicaciones	Servicio de Obra Publica
11725	62302011	Remozamiento de obra para el abastecimiento de agua	Servicio de Obra Publica
11726	62302012	Remozamiento de obra para el abastecimiento de gas	Servicio de Obra Publica
11727	62302013	Remozamiento de obra para el abastecimiento de petroleo	Servicio de Obra Publica
11728	62302014	Remozamiento de obra para la generacion de energia electrica	Servicio de Obra Publica
11729	62302015	Remozamiento de obra para las telecomunicaciones	Servicio de Obra Publica
11730	62302016	Ampliacion de obra para el abastecimiento de agua	Servicio de Obra Publica
11731	62302017	Ampliacion de obra para el abastecimiento de gas	Servicio de Obra Publica
11732	62302018	Ampliacion de obra para el abastecimiento de petroleo	Servicio de Obra Publica
11733	62302019	Ampliacion de obra para la generacion de energia electrica	Servicio de Obra Publica
11734	62302020	Ampliacion de obra para las telecomunicaciones	Servicio de Obra Publica
11735	62302021	Reparacion integral de obra para el abastecimiento de agua	Servicio de Obra Publica
11736	62302022	Reparacion integral de obra para el abastecimiento de gas	Servicio de Obra Publica
11737	62302023	Reparacion integral de obra para el abastecimiento de petroleo	Servicio de Obra Publica
11738	62302024	Reparacion integral de obra para la generacion de energia electrica	Servicio de Obra Publica
11739	62302025	Reparacion integral de obra para las telecomunicaciones	Servicio de Obra Publica
11740	6240	Division de terrenos y construccion de obras de urbanizacion	
11741	62401	Obras de preedificacion en terrenos de construccion	
11742	62401001	Demolicion de almacen	Obra
11743	62401002	Demolicion de camino	Obra
11744	62401003	Demolicion de canal	Obra
11745	62401004	Demolicion de carretera	Obra
11746	62401005	Demolicion de casa habitacion	Obra
11747	62401006	Demolicion de clinica o centro de salud	Obra
11748	62401007	Demolicion de edificio	Obra
11749	62401008	Demolicion de escollera	Obra
11750	62401010	Demolicion de hospital	Obra
11751	62401011	Demolicion de linea de transmision	Obra
11752	62401012	Demolicion de malecon	Obra
11753	62401013	Demolicion de muelle	Obra
11754	62401014	Demolicion de obra de agua potable	Obra
11755	62401015	Demolicion de obra de alumbrado	Obra
11756	62401016	Demolicion de obra de drenaje	Obra
11757	62401017	Demolicion de obra de electrificacion	Obra
11758	62401018	Demolicion de obra de irrigacion	Obra
11759	62401019	Demolicion de obra de pavimentacion	Obra
11760	62401020	Demolicion de obra de telefonia	Obra
11761	62401021	Demolicion de planta de tratamiento de agua potable	Obra
11762	62401022	Demolicion de planta de tratamiento de aguas residuales	Obra
11763	62401023	Demolicion de planta de tratamiento de gas	Obra
11764	62401024	Demolicion de planta geoelectrica	Obra
11765	62401025	Demolicion de planta hidroelectrica	Obra
11766	62401026	Demolicion de planta nucleoelectrica	Obra
11767	62401027	Demolicion de planta petroquimica	Obra
11768	62401028	Demolicion de planta termoelectrica	Obra
11769	62401029	Demolicion de presa	Obra
11770	62401030	Demolicion de puente	Obra
11771	62401031	Demolicion de red de distribucion	Obra
11772	62401034	Demolicion de terminal de almacenamiento y distribucion	Obra
11773	62401035	Obras de andamiaje	Obra
11774	62401036	Obras de demolicion	Obra
11775	62401037	Obras de excavacion y remocion de tierra	Obra
11776	62401038	Obras de investigacion de campo	Obra
11777	62401039	Obras de limpieza y preparacion de terreno	Obra
11778	62401040	Obras de preparacion de terreno para mineria (excepto extraccion de petroleo y gas)	Obra
11779	62402	Construccion de obras de urbanizacion	
11780	62402001	Construccion de banquetas	Obra
11781	62402002	Construccion de guarniciones	Obra
11782	62402003	Construccion de red de agua potable	Obra
11783	62402004	Construccion de red de alcantarillado	Obra
11784	62402005	Construccion de red de energia	Obra
11785	62402006	Estudios de preinversion y/o preparacion del proyecto para banquetas	Obra
11786	62402007	Estudios de preinversion y/o preparacion del proyecto para guarniciones	Obra
11787	62402008	Estudios de preinversion y/o preparacion del proyecto para red de agua potable	Obra
11788	62402009	Estudios de preinversion y/o preparacion del proyecto para red de alcantarillado	Obra
11789	62402010	Estudios de preinversion y/o preparacion del proyecto para red de energia	Obra
11790	62403	Mantenimiento y rehabilitacion de obras de urbanizacion	
11791	62403001	Conservacion y/o mantenimiento de banquetas	Servicio de Obra Publica
11792	62403002	Conservacion y/o mantenimiento de guarniciones	Servicio de Obra Publica
11793	62403003	Conservacion y/o mantenimiento de red de agua potable	Servicio de Obra Publica
11794	62403004	Conservacion y/o mantenimiento de red de alcantarillado	Servicio de Obra Publica
11795	62403005	Conservacion y/o mantenimiento de red de energia	Servicio de Obra Publica
11796	62403006	Rehabilitacion de banquetas	Servicio de Obra Publica
11797	62403007	Rehabilitacion de guarniciones	Servicio de Obra Publica
11798	62403008	Rehabilitacion de red de agua potable	Servicio de Obra Publica
11799	62403009	Rehabilitacion de red de alcantarillado	Servicio de Obra Publica
11800	62403010	Rehabilitacion de red de energia	Servicio de Obra Publica
11801	62403011	Remozamiento de banquetas	Servicio de Obra Publica
11802	62403012	Remozamiento de guarniciones	Servicio de Obra Publica
11803	62403013	Remozamiento de red de agua potable	Servicio de Obra Publica
11804	62403014	Remozamiento de red de alcantarillado	Servicio de Obra Publica
11805	62403015	Remozamiento de red de energia	Servicio de Obra Publica
11806	62403016	Ampliacion de banquetas	Servicio de Obra Publica
11807	62403017	Ampliacion de guarniciones	Servicio de Obra Publica
11808	62403018	Ampliacion de red de agua potable	Servicio de Obra Publica
11809	62403019	Ampliacion de red de alcantarillado	Servicio de Obra Publica
11810	62403020	Ampliacion de red de energia	Servicio de Obra Publica
11811	62403021	Reparacion integral de banquetas	Servicio de Obra Publica
11812	62403022	Reparacion integral de guarniciones	Servicio de Obra Publica
11813	62403023	Reparacion integral de red de agua potable	Servicio de Obra Publica
11814	62403024	Reparacion integral de red de alcantarillado	Servicio de Obra Publica
11815	62403025	Reparacion integral de red de energia	Servicio de Obra Publica
11816	6250	Construccion de vias de comunicacion	
11817	62501	Construccion de vias de comunicacion	
11818	62501001	Construccion aeropista	Obra
11819	62501002	Construccion autopista	Obra
11820	62501003	Construccion carretera	Obra
11821	62501004	Construccion de camino	Obra
11822	62501005	Construccion de pasos a desnivel	Obra
11823	62501006	Construccion de puente	Obra
11824	62501007	Construccion de terraceria	Obra
11825	62501008	Estudios de preinversion y/o preparacion del proyecto para aeropista	Obra
11826	62501009	Estudios de preinversion y/o preparacion del proyecto para autopista	Obra
11827	62501010	Estudios de preinversion y/o preparacion del proyecto para carretera	Obra
11828	62501011	Estudios de preinversion y/o preparacion del proyecto para pasos a desnivel	Obra
11829	62501012	Estudios de preinversion y/o preparacion del proyecto para puente	Obra
11830	62501013	Estudios de preinversion y/o preparacion del proyecto para terraceria	Obra
11831	62502	Mantenimiento y rehabilitacion de las vias de comunicacion	
11832	62502001	Conservacion y/o mantenimiento de aeropista	Servicio de Obra Publica
11833	62502002	Conservacion y/o mantenimiento de autopista	Servicio de Obra Publica
11834	62502003	Conservacion y/o mantenimiento pasos a desnivel	Servicio de Obra Publica
11835	62502004	Conservacion y/o mantenimiento de puente	Servicio de Obra Publica
11836	62502005	Conservacion y/o mantenimiento de terraceria	Servicio de Obra Publica
11837	62502006	Rehabilitacion de aeropista	Servicio de Obra Publica
11838	62502007	Rehabilitacion de autopista	Servicio de Obra Publica
11839	62502008	Rehabilitacion pasos a desnivel	Servicio de Obra Publica
11840	62502009	Rehabilitacion de puente	Servicio de Obra Publica
11841	62502010	Rehabilitacion de terraceria	Servicio de Obra Publica
11842	62502011	Remozamiento de aeropista	Servicio de Obra Publica
11843	62502012	Remozamiento de autopista	Servicio de Obra Publica
11844	62502013	Remozamiento pasos a desnivel	Servicio de Obra Publica
11845	62502014	Remozamiento de puente	Servicio de Obra Publica
11846	62502015	Remozamiento de terraceria	Servicio de Obra Publica
11847	62502016	Ampliacion de aeropista	Servicio de Obra Publica
11848	62502017	Ampliacion de autopista	Servicio de Obra Publica
11849	62502018	Ampliacion pasos a desnivel	Servicio de Obra Publica
11850	62502019	Ampliacion de puente	Servicio de Obra Publica
11851	62502020	Ampliacion de terraceria	Servicio de Obra Publica
11852	62502021	Reparacion integral de aeropista	Servicio de Obra Publica
11853	62502022	Reparacion integral de autopista	Servicio de Obra Publica
11854	62502023	Reparacion integral pasos a desnivel	Servicio de Obra Publica
11855	62502024	Reparacion integral de puente	Servicio de Obra Publica
11856	62502025	Reparacion integral de terraceria	Servicio de Obra Publica
11857	6260	Otras construcciones de ingenieria civil u obra pesada	
11858	62601	Otras construcciones de ingenieria civil u obra pesada	
11859	62601001	Construccion de presa y/o represa	Obra
11860	62601002	Construccion de obra maritima	Obra
11861	62601003	Construccion de obra fluvial	Obra
11862	62601004	Construccion de obra subacuatica	Obra
11863	62601005	Construccion de obra para el transporte electrico	Obra
11864	62601006	Construccion de obra para el transporte ferroviario	Obra
11865	62601007	Otra construccion de ingenieria civil	Obra
11866	62601008	Otra construccion de obra pesada	Obra
11867	62601009	Construccion de canal	Obra
11868	62601010	Construccion de carretera elevada (puente)	Obra
11869	62601011	Construccion de obra para mineria	Obra
11870	62601012	Estudios de preinversion y/o preparacion del proyecto para obra de construccion de presa y/o represa	Obra
11871	62601013	Estudios de preinversion y/o preparacion del proyecto para obra de construccion fluvial	Obra
11872	62601014	Estudios de preinversion y/o preparacion del proyecto para obra de construccion maritima	Obra
11873	62601015	Estudios de preinversion y/o preparacion del proyecto para obra de construccion para transporte electrico	Obra
11874	62601016	Estudios de preinversion y/o preparacion del proyecto para obra de construccion para transporte ferroviario	Obra
11875	62601017	Estudios de preinversion y/o preparacion del proyecto para obra de construccion subacuatica	Obra
11876	62601018	Estudios de preinversion y/o preparacion del proyecto para otra construccion de ingenieria civil	Obra
11877	62601019	Estudios de preinversion y/o preparacion del proyecto para otra construccion de obra pesada	Obra
11878	62602	Mantenimiento y rehabilitacion de otras obras de ingenieria civil u obras pesadas	
11879	62602001	Conservacion y/o mantenimiento de presa y/o represa	Servicio de Obra Publica
11880	62602002	Conservacion y/o mantenimiento de obra maritima	Servicio de Obra Publica
11881	62602003	Conservacion y/o mantenimiento de obra fluvial	Servicio de Obra Publica
11882	62602004	Conservacion y/o mantenimiento de obra subacuatica	Servicio de Obra Publica
11883	62602005	Conservacion y/o mantenimiento de obra para el transporte electrico	Servicio de Obra Publica
11884	62602006	Conservacion y/o mantenimiento de obra para el transporte ferroviario	Servicio de Obra Publica
11885	62602007	Conservacion y/o mantenimiento de otra obra de ingenieria civil	Servicio de Obra Publica
11886	62602008	Conservacion y/o mantenimiento de otra obra de construccion pesada	Servicio de Obra Publica
11887	62602009	Rehabilitacion de presa y/o represa	Servicio de Obra Publica
11888	62602010	Rehabilitacion de obra maritima	Servicio de Obra Publica
11889	62602011	Rehabilitacion de obra fluvial	Servicio de Obra Publica
11890	62602012	Rehabilitacion de obra subacuatica	Servicio de Obra Publica
11891	62602013	Rehabilitacion de obra para el transporte electrico	Servicio de Obra Publica
11892	62602014	Rehabilitacion de obra para el transporte ferroviario	Servicio de Obra Publica
11893	62602015	Rehabilitacion de otra obra de ingenieria civil	Servicio de Obra Publica
11894	62602016	Rehabilitacion de otra obra de construccion pesada	Servicio de Obra Publica
11895	62602017	Remozamiento de presa y/o represa	Servicio de Obra Publica
11896	62602018	Remozamiento de obra maritima	Servicio de Obra Publica
11897	62602019	Remozamiento de obra fluvial	Servicio de Obra Publica
11898	62602020	Remozamiento de obra subacuatica	Servicio de Obra Publica
11899	62602021	Remozamiento de obra para el transporte electrico	Servicio de Obra Publica
11900	62602022	Remozamiento de obra para el transporte ferroviario	Servicio de Obra Publica
11901	62602023	Remozamiento otra obra de ingenieria civil	Servicio de Obra Publica
11902	62602024	Remozamiento de otra obra de construccion pesada	Servicio de Obra Publica
11903	62602025	Ampliacion de presa y/o represa	Servicio de Obra Publica
11904	62602026	Ampliacion de obra maritima	Servicio de Obra Publica
11905	62602027	Ampliacion de obra fluvial	Servicio de Obra Publica
11906	62602028	Ampliacion de obra subacuatica	Servicio de Obra Publica
11907	62602029	Ampliacion de obra para el transporte electrico	Servicio de Obra Publica
11908	62602030	Ampliacion de obra para el transporte ferroviario	Servicio de Obra Publica
11909	62602031	Ampliacion de otra obra de ingenieria civil	Servicio de Obra Publica
11910	62602032	Ampliacion de otra obra de construccion pesada	Servicio de Obra Publica
11911	62602033	Reparacion integral de presa y/o represa	Servicio de Obra Publica
11912	62602034	Reparacion integral de obra maritima	Servicio de Obra Publica
11913	62602035	Reparacion integral de obra fluvial	Servicio de Obra Publica
11914	62602036	Reparacion integral de obra subacuatica	Servicio de Obra Publica
11915	62602037	Reparacion integral de obra para el transporte electrico	Servicio de Obra Publica
11916	62602038	Reparacion integral de obra para el transporte ferroviario	Servicio de Obra Publica
11917	62602039	Reparacion integral de otra obra de ingenieria civil	Servicio de Obra Publica
11918	62602040	Reparacion integral de otra obra de construccion pesada	Servicio de Obra Publica
11919	62602041	Dragado en canal	Servicio de Obra Publica
11920	62602042	Dragado en presa	Servicio de Obra Publica
11921	62602043	Dragado fluvial	Servicio de Obra Publica
11922	62602044	Dragado lacustre	Servicio de Obra Publica
11923	62602045	Dragado maritimo	Servicio de Obra Publica
11924	6270	Instalaciones y equipamiento en construcciones	
11925	62701	Instalaciones y obras de construccion especializada	
11926	62701001	Construccion de escollera	Obra
11927	62701002	Construccion de gasoducto	Obra
11928	62701003	Construccion de gasolinoducto	Obra
11929	62701004	Construccion de linea de transmision	Obra
11930	62701005	Construccion de malecon	Obra
11931	62701006	Construccion de muelle	Obra
11932	62701007	Construccion de obra de agua potable	Obra
11933	62701008	Construccion de obra de alumbrado	Obra
11934	62701009	Construccion de obra de drenaje	Obra
11935	62701010	Construccion de obra de electrificacion	Obra
11936	62701011	Construccion de obra de irrigacion	Obra
11937	62701012	Construccion de obra de pavimentacion	Obra
11938	62701013	Construccion de obra de telefonia	Obra
11939	62701014	Construccion de oleoducto	Obra
11940	62701015	Construccion de planta de tratamiento de agua potable	Obra
11941	62701016	Construccion de planta de tratamiento de aguas residuales	Obra
11942	62701017	Construccion de planta de tratamiento de gas	Obra
11943	62701018	Construccion de planta geoelectrica	Obra
11944	62701019	Construccion de planta hidroelectrica	Obra
11945	62701020	Construccion de planta nucleoelectrica	Obra
11946	62701021	Construccion de planta petroquimica	Obra
11947	62701022	Construccion de planta termoelectrica	Obra
11948	62701023	Construccion de poliducto	Obra
11949	62701024	Construccion de presa	Obra
11950	62701025	Construccion de red de distribucion	Obra
11951	62701026	Construccion de refineria	Obra
11952	62701027	Construccion de terminal de almacenamiento y distribucion	Obra
11953	62701028	Maniobras con grua	Obra
11954	62701029	Obra de construccion de enrejados y pasamanos	Obra
11955	62701030	Obras de aislamiento (cableado electrico, agua, calefaccion, sonido)	Obra
11956	62701031	Obras de albañileria	Obra
11957	62701032	Obras de calefaccion, ventilacion o aire acondicionado	Obra
11958	62701033	Obras de doblaje y edificacion de acero, incluye soldadura.	Obra
11959	62701034	Obras de edificacion incluyendo la instalacion de pilotes	Obra
11960	62701035	Obras de instalacion de pilotes	Obra
11961	62701036	Obras de perforacion de pozos	Obra
11962	62701037	Obras de perforacion de pozos de agua	Obra
11963	62701038	Obras de plomeria hidraulica o de tendido de drenaje	Obra
11964	62701039	Obras de techado e impermeabilizacion	Obra
11965	62701040	Obras de tendido de concreto.	Obra
11966	62701041	Obras electricas	Obra
11967	62701042	Obras para la construccion de conexiones de gas	Obra
11968	62701043	Perforacion de pozo de exploracion en mar	Obra
11969	62701044	Perforacion de pozo de exploracion en tierra	Obra
11970	62701045	Perforacion de pozo de produccion en mar	Obra
11971	62701046	Perforacion de pozo de produccion en tierra	Obra
11972	62701047	Reconfiguracion de planta de tratamiento de gas	Obra
11973	62701048	Reconfiguracion de planta petroquimica	Obra
11974	62701049	Reconfiguracion de refineria	Obra
11975	62701050	Recuperacion de ductos	Obra
11976	62701051	Reparacion de pozo de produccion	Obra
11977	62701052	Estudios de preinversion y/o preparacion del proyecto para instalacion de aire acondicionado	Obra
11978	62701053	Estudios de preinversion y/o preparacion del proyecto para instalacion de calefaccion	Obra
11979	62701054	Estudios de preinversion y/o preparacion del proyecto para instalacion de suministro de gas	Obra
11980	62701055	Estudios de preinversion y/o preparacion del proyecto para instalacion electrica	Obra
11981	62701056	Estudios de preinversion y/o preparacion del proyecto para instalacion en obra no clasificada	Obra
11982	62701057	Estudios de preinversion y/o preparacion del proyecto para instalacion hidrosanitaria	Obra
11983	62701058	Estudios de preinversion y/o preparacion del proyecto para instalacion electromecanica	Obra
11984	6290	Trabajos de acabados en edificaciones y otros trabajos especializados	
11985	62901	Ensamble y edificacion de construcciones prefabricadas	
11986	62901001	Obra de ensamble y/o edificacion de construccion prefabricada	Obra
11987	62902	Obras de terminacion y acabado de edificios	
11988	62902001	Colocacion de azulejos	Servicio de Obra Publica
11989	62902002	Embaldosado y/o colocacion de pisos	Servicio de Obra Publica
11990	62902003	Instalacion de canceleria en inmueble	Servicio de Obra Publica
11991	62902004	Instalacion de productos de carpinteria en inmuebles	Servicio de Obra Publica
11992	62902005	Instalacion de productos metalicos en inmuebles	Servicio de Obra Publica
11993	62902006	Instalacion de ventanas	Servicio de Obra Publica
11994	62902007	Obra de decoracion y/o ornamentacion de inmueble	Servicio de Obra Publica
11995	62902008	Obra de ornamentacion	Servicio de Obra Publica
11996	62902009	Obras de decoracion de interiores	Servicio de Obra Publica
11997	62902010	Obras de embaldosado de pisos y colocacion de azulejos en paredes	Servicio de Obra Publica
11998	62902011	Obras de enyesado	Servicio de Obra Publica
11999	62902012	Obras de pintado	Servicio de Obra Publica
12000	62902013	Obras de sellado e instalacion de ventanas	Servicio de Obra Publica
12001	62902014	Obras en madera o metal y carpinteria	Servicio de Obra Publica
12002	62902015	Tapizado de inmueble	Servicio de Obra Publica
12003	62903	Servicios de supervision de obras	
12004	62903001	Supervision de obras publicas	Servicio de Obra Publica
12005	62904	Servicios para la liberacion de derechos de via	
12006	62904001	Servicios para la liberacion de derechos de via	Servicio de Obra Publica
12007	62905	Otros servicios relacionados con obras publicas	
12008	62905001	Arrendamientos relacionados con equipos para la construccion, demolicion de edificios u obras de ingenieria civil	Servicio de Obra Publica
12009	62905002	Diseño arquitectonico	Servicio de Obra Publica
12010	62905003	Diseño artistico para obra publica	Servicio de Obra Publica
12011	62905004	Diseño de ingenieria electromecanica para obra publica	Servicio de Obra Publica
12012	62905005	Diseño de ingenieria industrial para obra publica	Servicio de Obra Publica
12013	62905006	Estudio de aerofotogrametria	Servicio de Obra Publica
12014	62905007	Estudio de control de calidad para obra publica	Servicio de Obra Publica
12015	62905008	Estudio de geofisica	Servicio de Obra Publica
12016	62905009	Estudio de geologia	Servicio de Obra Publica
12017	62905010	Estudio de geotermia	Servicio de Obra Publica
12018	62905011	Estudio de hidrologia para obra publica	Servicio de Obra Publica
12019	62905012	Estudio de impacto ambiental para obra publica	Servicio de Obra Publica
12020	62905013	Estudio de informatica y sistemas para obra publica	Servicio de Obra Publica
12021	62905014	Estudio de ingenieria de transito para obra publica	Servicio de Obra Publica
12022	62905015	Estudio de mecanica del suelo para obra publica	Servicio de Obra Publica
12023	62905016	Estudio de oceonografia y/o meteorologia	Servicio de Obra Publica
12024	62905017	Estudio de radiografia industrial para obra publica	Servicio de Obra Publica
12025	62905018	Estudio de resistencia de materiales para obra publica	Servicio de Obra Publica
12026	62905019	Estudio de restitucion de la eficiencia de las instalaciones para obra publica	Servicio de Obra Publica
12027	62905020	Estudio de trabajo de organizacion para obra publica	Servicio de Obra Publica
12028	62905021	Estudio ecologico y de impacto ambiental	Servicio de Obra Publica
12029	62905022	Estudio tecnico de agronomia y desarrollo pecuario para obra publica	Servicio de Obra Publica
12030	62905023	Estudio tecnico relacionados con obra publica	Servicio de Obra Publica
12031	62905024	Estudio topografico	Servicio de Obra Publica
12032	62905025	Estudios de tenencia de la tierra	Servicio de Obra Publica
12033	62905026	Servicios de apoyo a la calidad del agua	Servicio de Obra Publica
12034	62905027	Servicios de apoyo a la calidad del aire	Servicio de Obra Publica
12035	62905028	Servicios de dragado	Servicio de Obra Publica
12036	62905029	Servicios de topografia	Servicio de Obra Publica
12037	62905030	Estudios de preinversion y/o preparacion del proyecto para alquiler de maquinaria y/o equipo para construccion con operador	Servicio de Obra Publica
12038	62905031	Estudios de preinversion y/o preparacion del proyecto para aplicacion de cubrimientos en inmuebles	Servicio de Obra Publica
12039	62905032	Estudios de preinversion y/o preparacion del proyecto para aplicacion de pintura en inmuebles	Servicio de Obra Publica
12040	62905033	Estudios de preinversion y/o preparacion del proyecto para colocacion de muros	Servicio de Obra Publica
12041	62905034	Estudios de preinversion y/o preparacion del proyecto para colocacion de pisos y/o azulejos	Servicio de Obra Publica
12042	62905035	Estudios de preinversion y/o preparacion del proyecto para demolicion de edificaciones	Servicio de Obra Publica
12043	62905036	Estudios de preinversion y/o preparacion del proyecto para demolicion de estructuras	Servicio de Obra Publica
12044	62905037	Estudios de preinversion y/o preparacion del proyecto para enyesado de inmuebles	Servicio de Obra Publica
12045	62905038	Estudios de preinversion y/o preparacion del proyecto para excavacion de terreno	Servicio de Obra Publica
12046	62905039	Estudios de preinversion y/o preparacion del proyecto para impermeabilizacion de inmuebles	Servicio de Obra Publica
12047	62905040	Estudios de preinversion y/o preparacion del proyecto para instalacion de canceleria en inmuebles	Servicio de Obra Publica
12048	62905041	Estudios de preinversion y/o preparacion del proyecto para instalacion de productos de carpinteria en inmuebles	Servicio de Obra Publica
12049	62905042	Estudios de preinversion y/o preparacion del proyecto para preparacion de terreno para construccion	Servicio de Obra Publica
\.


--
-- Data for Name: language; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.language (id, alpha2, name) FROM stdin;
1	aa	Afar
2	ab	Abkhazian
3	ae	Avestan
4	af	Afrikaans
5	ak	Akan
6	am	Amharic
7	an	Aragonese
8	ar	Arabic
9	as	Assamese
10	av	Avaric
11	ay	Aymara
12	az	Azerbaijani
13	ba	Bashkir
14	be	Belarusian
15	bg	Bulgarian
16	bh	Bihari languages
17	bi	Bislama
18	bm	Bambara
19	bn	Bengali
20	bo	Tibetan
21	br	Breton
22	bs	Bosnian
23	ca	Catalan; Valencian
24	ce	Chechen
25	ch	Chamorro
26	co	Corsican
27	cr	Cree
28	cs	Czech
29	cu	Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic
30	cv	Chuvash
31	cy	Welsh
32	da	Danish
33	de	German
34	dv	Divehi; Dhivehi; Maldivian
35	dz	Dzongkha
36	ee	Ewe
37	el	Greek, Modern (1453-)
38	en	English
39	eo	Esperanto
40	es	Spanish; Castilian
41	et	Estonian
42	eu	Basque
43	fa	Persian
44	ff	Fulah
45	fi	Finnish
46	fj	Fijian
47	fo	Faroese
48	fr	French
49	fy	Western Frisian
50	ga	Irish
51	gd	Gaelic; Scottish Gaelic
52	gl	Galician
53	gn	Guarani
54	gu	Gujarati
55	gv	Manx
56	ha	Hausa
57	he	Hebrew
58	hi	Hindi
59	ho	Hiri Motu
60	hr	Croatian
61	ht	Haitian; Haitian Creole
62	hu	Hungarian
63	hy	Armenian
64	hz	Herero
65	ia	Interlingua (International Auxiliary Language Association)
66	id	Indonesian
67	ie	Interlingue; Occidental
68	ig	Igbo
69	ii	Sichuan Yi; Nuosu
70	ik	Inupiaq
71	io	Ido
72	is	Icelandic
73	it	Italian
74	iu	Inuktitut
75	ja	Japanese
76	jv	Javanese
77	ka	Georgian
78	kg	Kongo
79	ki	Kikuyu; Gikuyu
80	kj	Kuanyama; Kwanyama
81	kk	Kazakh
82	kl	Kalaallisut; Greenlandic
83	km	Central Khmer
84	kn	Kannada
85	ko	Korean
86	kr	Kanuri
87	ks	Kashmiri
88	ku	Kurdish
89	kv	Komi
90	kw	Cornish
91	ky	Kirghiz; Kyrgyz
92	la	Latin
93	lb	Luxembourgish; Letzeburgesch
94	lg	Ganda
95	li	Limburgan; Limburger; Limburgish
96	ln	Lingala
97	lo	Lao
98	lt	Lithuanian
99	lu	Luba-Katanga
100	lv	Latvian
101	mg	Malagasy
102	mh	Marshallese
103	mi	Maori
104	mk	Macedonian
105	ml	Malayalam
106	mn	Mongolian
107	mr	Marathi
108	ms	Malay
109	mt	Maltese
110	my	Burmese
111	na	Nauru
112	nb	Bokmål, Norwegian; Norwegian Bokmål
113	nd	Ndebele, North; North Ndebele
114	ne	Nepali
115	ng	Ndonga
116	nl	Dutch; Flemish
117	nn	Norwegian Nynorsk; Nynorsk, Norwegian
118	no	Norwegian
119	nr	Ndebele, South; South Ndebele
120	nv	Navajo; Navaho
121	ny	Chichewa; Chewa; Nyanja
122	oc	Occitan (post 1500); Provençal
123	oj	Ojibwa
124	om	Oromo
125	or	Oriya
126	os	Ossetian; Ossetic
127	pa	Panjabi; Punjabi
128	pi	Pali
129	pl	Polish
130	ps	Pushto; Pashto
131	pt	Portuguese
132	qu	Quechua
133	rm	Romansh
134	rn	Rundi
135	ro	Romanian; Moldavian; Moldovan
136	ru	Russian
137	rw	Kinyarwanda
138	sa	Sanskrit
139	sc	Sardinian
140	sd	Sindhi
141	se	Northern Sami
142	sg	Sango
143	si	Sinhala; Sinhalese
144	sk	Slovak
145	sl	Slovenian
146	sm	Samoan
147	sn	Shona
148	so	Somali
149	sq	Albanian
150	sr	Serbian
151	ss	Swati
152	st	Sotho, Southern
153	su	Sundanese
154	sv	Swedish
155	sw	Swahili
156	ta	Tamil
157	te	Telugu
158	tg	Tajik
159	th	Thai
160	ti	Tigrinya
161	tk	Turkmen
162	tl	Tagalog
163	tn	Tswana
164	to	Tonga (Tonga Islands)
165	tr	Turkish
166	ts	Tsonga
167	tt	Tatar
168	tw	Twi
169	ty	Tahitian
170	ug	Uighur; Uyghur
171	uk	Ukrainian
172	ur	Urdu
173	uz	Uzbek
174	ve	Venda
175	vi	Vietnamese
176	vo	Volapük
177	wa	Walloon
178	wo	Wolof
179	xh	Xhosa
180	yi	Yiddish
181	yo	Yoruba
182	za	Zhuang; Chuang
183	zh	Chinese
184	zu	Zulu
\.


--
-- Data for Name: links; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.links (id, json, xlsx, pdf, contractingprocess_id) FROM stdin;
\.


--
-- Data for Name: log_gdmx; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.log_gdmx (id, date, cp, recordid, record) FROM stdin;
\.


--
-- Data for Name: logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.logs (id, version, update_date, publisher, release_file, release_json, record_json, contractingprocess_id, version_json, published) FROM stdin;
\.


--
-- Data for Name: memberof; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.memberof (id, memberofid, principal_parties_id, parties_id) FROM stdin;
\.


--
-- Data for Name: metadata; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.metadata (field_name, value) FROM stdin;
\.


--
-- Data for Name: milestonetype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.milestonetype (id, code, title, description) FROM stdin;
1	preProcurement	Pre-procurement milestones	For events during the planning or pre-procurement phase of a process, such as the preparation of key studies.
2	approval	Approval	For events such as the sign-off of a contract or project.
3	engagement	Engagement milestones	For engagement milestones, such as a public hearing.
4	assessment	Assessment milestones	For assessment and adjudication milestones, such as the meeting date of a committee.
5	delivery	Delivery milestones	For delivery milestones, such as the date when a good or service should be provided.
6	reporting	Reporting milestones	For reporting milestones, such as when key reports should be provided.
7	financing	Financing milestones	For events such as planned payments, or equity transfers in public private partnership projects.
8	publicNotices	Public notices	For milestones in which aspects related to public works are specified, such as the closure of streets, changes of traffic, etc.
\.


--
-- Data for Name: parties; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parties (contractingprocess_id, id, partyid, name, "position", identifier_scheme, identifier_id, identifier_legalname, identifier_uri, address_streetaddress, address_locality, address_region, address_postalcode, address_countryname, contactpoint_name, contactpoint_email, contactpoint_telephone, contactpoint_faxnumber, contactpoint_url, details, naturalperson, contactpoint_type, contactpoint_language, surname, additionalsurname, contactpoint_surname, contactpoint_additionalsurname, givenname, contactpoint_givenname) FROM stdin;
\.


--
-- Data for Name: partiesadditionalidentifiers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.partiesadditionalidentifiers (id, contractingprocess_id, parties_id, scheme, legalname, uri) FROM stdin;
\.


--
-- Data for Name: paymentmethod; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.paymentmethod (id, code, title, description) FROM stdin;
1	cash	Cash	
2	check	Check	
3	wireTransfer	Wire Transfe	
\.


--
-- Data for Name: planning; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.planning (id, contractingprocess_id, hasquotes, rationale, numberofbeneficiaries) FROM stdin;
\.


--
-- Data for Name: planningdocuments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.planningdocuments (id, contractingprocess_id, planning_id, documentid, document_type, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: pntreference; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pntreference (id, contractingprocess_id, contractid, format, record_id, "position", field_id, reference_id, date, isroot, error) FROM stdin;
\.


--
-- Data for Name: prefixocid; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.prefixocid (id, value) FROM stdin;
\.


--
-- Data for Name: programaticstructure; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.programaticstructure (id, cve, year, trimester, branch, branch_desc, finality, finality_desc, function, function_desc, subfunction, subfunction_desc, institutionalactivity, institutionalactivity_desc, budgetprogram, budgetprogram_desc, strategicobjective, strategicobjective_desc, responsibleunit, responsibleunit_desc, requestingunit, requestingunit_desc, spendingtype, spendingtype_desc, specificactivity, specificactivity_desc, spendingobject, spendingobject_desc, region, region_desc, budgetsource, budgetsource_desc, portfoliokey, approvedamount, modifiedamount, executedamount, committedamount, reservedamount) FROM stdin;
\.


--
-- Data for Name: publisher; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.publisher (id, contractingprocess_id, name, scheme, uid, uri) FROM stdin;
\.


--
-- Data for Name: quotes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.quotes (id, requestforquotes_id, quotes_id, description, date, value, quoteperiod_startdate, quoteperiod_enddate, issuingsupplier_id) FROM stdin;
\.


--
-- Data for Name: quotesitems; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.quotesitems (id, quotes_id, itemid, item, quantity) FROM stdin;
\.


--
-- Data for Name: relatedprocedure; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.relatedprocedure (id, contractingprocess_id, relatedprocedure_id, relationship_type, title, identifier_scheme, relatedprocedure_identifier, url) FROM stdin;
\.


--
-- Data for Name: requestforquotes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.requestforquotes (id, contractingprocess_id, planning_id, requestforquotes_id, title, description, period_startdate, period_enddate) FROM stdin;
\.


--
-- Data for Name: requestforquotesinvitedsuppliers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.requestforquotesinvitedsuppliers (id, requestforquotes_id, parties_id) FROM stdin;
\.


--
-- Data for Name: requestforquotesitems; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.requestforquotesitems (id, requestforquotes_id, itemid, item, quantity) FROM stdin;
\.


--
-- Data for Name: rolecatalog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rolecatalog (id, code, title, description) FROM stdin;
1	buyer	Buyer	The buyer is the entity whose budget will be used to purchase the goods.
2	procuringEntity	Procuring Entity	The entity managing the procurement, which may be different from the buyer who is paying / using the items being procured.
3	supplier	Supplier	The entity awarded or contracted to provide supplies, works or services.
4	tenderer	Tenderer	All entities who submit a tender
5	funder	Funder	The funder is an entity providing money or finance for this contracting process.
6	enquirer	Enquirer	A party who has made an enquiry during the enquiry phase of a contracting process.
7	payer	Payer	A party making a payment from a transaction
8	payee	Payee	A party in receipt of a payment from a transaction
9	reviewBody	Review Body	A party responsible for the review of this procurement process. This party often has a role in any challenges made to the contract award.
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (contractingprocess_id, parties_id, id, buyer, procuringentity, supplier, tenderer, funder, enquirer, payer, payee, reviewbody, attendee, official, invitedsupplier, issuingsupplier, guarantor, requestingunit, contractingunit, technicalunit, responsibleunit) FROM stdin;
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tags (id, contractingprocess_id, planning, planningupdate, tender, tenderamendment, tenderupdate, tendercancellation, award, awardupdate, awardcancellation, contract, contractupdate, contractamendment, implementation, implementationupdate, contracttermination, compiled, stage, register_date) FROM stdin;
\.


--
-- Data for Name: tender; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tender (id, contractingprocess_id, tenderid, title, description, status, minvalue_amount, minvalue_currency, value_amount, value_currency, procurementmethod, procurementmethod_details, procurementmethod_rationale, mainprocurementcategory, additionalprocurementcategories, awardcriteria, awardcriteria_details, submissionmethod, submissionmethod_details, tenderperiod_startdate, tenderperiod_enddate, enquiryperiod_startdate, enquiryperiod_enddate, hasenquiries, eligibilitycriteria, awardperiod_startdate, awardperiod_enddate, numberoftenderers, amendment_date, amendment_rationale, procurementmethod_rationale_id) FROM stdin;
\.


--
-- Data for Name: tenderamendmentchanges; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tenderamendmentchanges (id, contractingprocess_id, tender_id, property, former_value, amendments_date, amendments_rationale, amendments_id, amendments_description) FROM stdin;
\.


--
-- Data for Name: tenderdocuments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tenderdocuments (id, contractingprocess_id, tender_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: tenderitem; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tenderitem (id, contractingprocess_id, tender_id, itemid, description, classification_scheme, classification_id, classification_description, classification_uri, quantity, unit_name, unit_value_amount, unit_value_currency, unit_value_amountnet, latitude, longitude, location_postalcode, location_countryname, location_streetaddress, location_region, location_locality) FROM stdin;
\.


--
-- Data for Name: tenderitemadditionalclassifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tenderitemadditionalclassifications (id, contractingprocess_id, tenderitem_id, scheme, description, uri) FROM stdin;
\.


--
-- Data for Name: tendermilestone; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tendermilestone (id, contractingprocess_id, tender_id, milestoneid, title, description, duedate, date_modified, status, type) FROM stdin;
\.


--
-- Data for Name: tendermilestonedocuments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tendermilestonedocuments (id, contractingprocess_id, tender_id, milestone_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: user_contractingprocess; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_contractingprocess (id, user_id, contractingprocess_id) FROM stdin;
\.


--
-- Name: additionalcontactpoints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.additionalcontactpoints_id_seq', 1, false);


--
-- Name: award_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.award_id_seq', 1, false);


--
-- Name: awardamendmentchanges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.awardamendmentchanges_id_seq', 1, false);


--
-- Name: awarddocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.awarddocuments_id_seq', 1, false);


--
-- Name: awarditem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.awarditem_id_seq', 1, false);


--
-- Name: awarditemadditionalclassifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.awarditemadditionalclassifications_id_seq', 1, false);


--
-- Name: awardsupplier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.awardsupplier_id_seq', 1, false);


--
-- Name: budget_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.budget_id_seq', 1, false);


--
-- Name: budgetbreakdown_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.budgetbreakdown_id_seq', 1, false);


--
-- Name: budgetclassifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.budgetclassifications_id_seq', 1, false);


--
-- Name: clarificationmeeting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clarificationmeeting_id_seq', 1, false);


--
-- Name: clarificationmeetingactor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clarificationmeetingactor_id_seq', 1, false);


--
-- Name: contract_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.contract_id_seq', 1, false);


--
-- Name: contractamendmentchanges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.contractamendmentchanges_id_seq', 1, false);


--
-- Name: contractdocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.contractdocuments_id_seq', 1, false);


--
-- Name: contractingprocess_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.contractingprocess_id_seq', 1, false);


--
-- Name: contractitem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.contractitem_id_seq', 1, false);


--
-- Name: contractitemadditionalclasifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.contractitemadditionalclasifications_id_seq', 1, false);


--
-- Name: currency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.currency_id_seq', 1, false);


--
-- Name: datapnt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.datapnt_id_seq', 1, false);


--
-- Name: documentformat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.documentformat_id_seq', 1, false);


--
-- Name: documentmanagement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.documentmanagement_id_seq', 1, false);


--
-- Name: documenttype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.documenttype_id_seq', 1, false);


--
-- Name: gdmx_dictionary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.gdmx_dictionary_id_seq', 1, false);


--
-- Name: gdmx_document_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.gdmx_document_id_seq', 1, false);


--
-- Name: guarantees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.guarantees_id_seq', 1, false);


--
-- Name: implementation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.implementation_id_seq', 1, false);


--
-- Name: implementationdocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.implementationdocuments_id_seq', 1, false);


--
-- Name: implementationmilestone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.implementationmilestone_id_seq', 1, false);


--
-- Name: implementationmilestonedocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.implementationmilestonedocuments_id_seq', 1, false);


--
-- Name: implementationstatus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.implementationstatus_id_seq', 1, false);


--
-- Name: implementationtransactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.implementationtransactions_id_seq', 1, false);


--
-- Name: item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_id_seq', 1, false);


--
-- Name: language_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.language_id_seq', 1, false);


--
-- Name: links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.links_id_seq', 1, false);


--
-- Name: log_gdmx_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.log_gdmx_id_seq', 1, false);


--
-- Name: logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.logs_id_seq', 1, false);


--
-- Name: memberof_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.memberof_id_seq', 1, false);


--
-- Name: milestonetype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.milestonetype_id_seq', 1, false);


--
-- Name: parties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.parties_id_seq', 1, false);


--
-- Name: partiesadditionalidentifiers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.partiesadditionalidentifiers_id_seq', 1, false);


--
-- Name: paymentmethod_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.paymentmethod_id_seq', 1, false);


--
-- Name: planning_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.planning_id_seq', 1, false);


--
-- Name: planningdocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.planningdocuments_id_seq', 1, false);


--
-- Name: pntreference_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pntreference_id_seq', 1, false);


--
-- Name: prefixocid_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.prefixocid_id_seq', 1, false);


--
-- Name: programaticstructure_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.programaticstructure_id_seq', 1, false);


--
-- Name: publisher_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.publisher_id_seq', 1, false);


--
-- Name: quotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.quotes_id_seq', 1, false);


--
-- Name: quotesitems_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.quotesitems_id_seq', 1, false);


--
-- Name: relatedprocedure_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.relatedprocedure_id_seq', 1, false);


--
-- Name: requestforquotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.requestforquotes_id_seq', 1, false);


--
-- Name: requestforquotesinvitedsuppliers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.requestforquotesinvitedsuppliers_id_seq', 1, false);


--
-- Name: requestforquotesitems_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.requestforquotesitems_id_seq', 1, false);


--
-- Name: rolecatalog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rolecatalog_id_seq', 1, false);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_id_seq', 1, false);


--
-- Name: tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tags_id_seq', 1, false);


--
-- Name: tender_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tender_id_seq', 1, false);


--
-- Name: tenderamendmentchanges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tenderamendmentchanges_id_seq', 1, false);


--
-- Name: tenderdocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tenderdocuments_id_seq', 1, false);


--
-- Name: tenderitem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tenderitem_id_seq', 1, false);


--
-- Name: tenderitemadditionalclassifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tenderitemadditionalclassifications_id_seq', 1, false);


--
-- Name: tendermilestone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tendermilestone_id_seq', 1, false);


--
-- Name: tendermilestonedocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tendermilestonedocuments_id_seq', 1, false);


--
-- Name: user_contractingprocess_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_contractingprocess_id_seq', 1, false);


--
-- Name: additionalcontactpoints additionalcontactpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.additionalcontactpoints
    ADD CONSTRAINT additionalcontactpoints_pkey PRIMARY KEY (id);


--
-- Name: award award_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.award
    ADD CONSTRAINT award_pkey PRIMARY KEY (id);


--
-- Name: awardamendmentchanges awardamendmentchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: awarddocuments awarddocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarddocuments
    ADD CONSTRAINT awarddocuments_pkey PRIMARY KEY (id);


--
-- Name: awarditem awarditem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditem
    ADD CONSTRAINT awarditem_pkey PRIMARY KEY (id);


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_pkey PRIMARY KEY (id);


--
-- Name: awardsupplier awardsupplier_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardsupplier
    ADD CONSTRAINT awardsupplier_pkey PRIMARY KEY (id);


--
-- Name: budget budget_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_pkey PRIMARY KEY (id);


--
-- Name: budgetbreakdown budgetbreakdown_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgetbreakdown
    ADD CONSTRAINT budgetbreakdown_pkey PRIMARY KEY (id);


--
-- Name: budgetclassifications budgetclassifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgetclassifications
    ADD CONSTRAINT budgetclassifications_pkey PRIMARY KEY (id);


--
-- Name: clarificationmeeting clarificationmeeting_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeeting
    ADD CONSTRAINT clarificationmeeting_pkey PRIMARY KEY (id);


--
-- Name: clarificationmeetingactor clarificationmeetingactor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_pkey PRIMARY KEY (id);


--
-- Name: contract contract_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract
    ADD CONSTRAINT contract_pkey PRIMARY KEY (id);


--
-- Name: contractamendmentchanges contractamendmentchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: contractdocuments contractdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractdocuments
    ADD CONSTRAINT contractdocuments_pkey PRIMARY KEY (id);


--
-- Name: contractingprocess contractingprocess_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractingprocess
    ADD CONSTRAINT contractingprocess_pkey PRIMARY KEY (id);


--
-- Name: contractitem contractitem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitem
    ADD CONSTRAINT contractitem_pkey PRIMARY KEY (id);


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_pkey PRIMARY KEY (id);


--
-- Name: currency currency_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (id);


--
-- Name: datapnt datapnt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datapnt
    ADD CONSTRAINT datapnt_pkey PRIMARY KEY (id);


--
-- Name: documentformat documentformat_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentformat
    ADD CONSTRAINT documentformat_pkey PRIMARY KEY (id);


--
-- Name: documentmanagement documentmanagement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentmanagement
    ADD CONSTRAINT documentmanagement_pkey PRIMARY KEY (id);


--
-- Name: documenttype documenttype_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key UNIQUE (code);


--
-- Name: documenttype documenttype_code_key1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key1 UNIQUE (code);


--
-- Name: documenttype documenttype_code_key2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key2 UNIQUE (code);


--
-- Name: documenttype documenttype_code_key3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key3 UNIQUE (code);


--
-- Name: documenttype documenttype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_pkey PRIMARY KEY (id);


--
-- Name: gdmx_dictionary gdmx_dictionary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gdmx_dictionary
    ADD CONSTRAINT gdmx_dictionary_pkey PRIMARY KEY (id);


--
-- Name: gdmx_document gdmx_document_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gdmx_document
    ADD CONSTRAINT gdmx_document_pkey PRIMARY KEY (id);


--
-- Name: guarantees guarantees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guarantees
    ADD CONSTRAINT guarantees_pkey PRIMARY KEY (id);


--
-- Name: implementation implementation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementation
    ADD CONSTRAINT implementation_pkey PRIMARY KEY (id);


--
-- Name: implementationdocuments implementationdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_pkey PRIMARY KEY (id);


--
-- Name: implementationmilestone implementationmilestone_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_pkey PRIMARY KEY (id);


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_pkey PRIMARY KEY (id);


--
-- Name: implementationstatus implementationstatus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationstatus
    ADD CONSTRAINT implementationstatus_pkey PRIMARY KEY (id);


--
-- Name: implementationtransactions implementationtransactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_pkey PRIMARY KEY (id);


--
-- Name: item item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item
    ADD CONSTRAINT item_pkey PRIMARY KEY (id);


--
-- Name: language language_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (id);


--
-- Name: links links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_pkey PRIMARY KEY (id);


--
-- Name: log_gdmx log_gdmx_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_gdmx
    ADD CONSTRAINT log_gdmx_pkey PRIMARY KEY (id);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: memberof memberof_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberof
    ADD CONSTRAINT memberof_pkey PRIMARY KEY (id);


--
-- Name: milestonetype milestonetype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.milestonetype
    ADD CONSTRAINT milestonetype_pkey PRIMARY KEY (id);


--
-- Name: parties parties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parties
    ADD CONSTRAINT parties_pkey PRIMARY KEY (id);


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_pkey PRIMARY KEY (id);


--
-- Name: paymentmethod paymentmethod_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paymentmethod
    ADD CONSTRAINT paymentmethod_pkey PRIMARY KEY (id);


--
-- Name: metadata pk_metadata_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata
    ADD CONSTRAINT pk_metadata_id PRIMARY KEY (field_name);


--
-- Name: planning planning_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning
    ADD CONSTRAINT planning_pkey PRIMARY KEY (id);


--
-- Name: planningdocuments planningdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planningdocuments
    ADD CONSTRAINT planningdocuments_pkey PRIMARY KEY (id);


--
-- Name: pntreference pntreference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pntreference
    ADD CONSTRAINT pntreference_pkey PRIMARY KEY (id);


--
-- Name: prefixocid prefixocid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prefixocid
    ADD CONSTRAINT prefixocid_pkey PRIMARY KEY (id);


--
-- Name: programaticstructure programaticstructure_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programaticstructure
    ADD CONSTRAINT programaticstructure_pkey PRIMARY KEY (id);


--
-- Name: publisher publisher_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publisher
    ADD CONSTRAINT publisher_pkey PRIMARY KEY (id);


--
-- Name: quotes quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_pkey PRIMARY KEY (id);


--
-- Name: quotesitems quotesitems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotesitems
    ADD CONSTRAINT quotesitems_pkey PRIMARY KEY (id);


--
-- Name: relatedprocedure relatedprocedure_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relatedprocedure
    ADD CONSTRAINT relatedprocedure_pkey PRIMARY KEY (id);


--
-- Name: requestforquotes requestforquotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotes
    ADD CONSTRAINT requestforquotes_pkey PRIMARY KEY (id);


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_pkey PRIMARY KEY (id);


--
-- Name: requestforquotesitems requestforquotesitems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesitems
    ADD CONSTRAINT requestforquotesitems_pkey PRIMARY KEY (id);


--
-- Name: rolecatalog rolecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rolecatalog
    ADD CONSTRAINT rolecatalog_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tender tender_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tender
    ADD CONSTRAINT tender_pkey PRIMARY KEY (id);


--
-- Name: tenderamendmentchanges tenderamendmentchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: tenderdocuments tenderdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderdocuments
    ADD CONSTRAINT tenderdocuments_pkey PRIMARY KEY (id);


--
-- Name: tenderitem tenderitem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitem
    ADD CONSTRAINT tenderitem_pkey PRIMARY KEY (id);


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_pkey PRIMARY KEY (id);


--
-- Name: tendermilestone tendermilestone_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestone
    ADD CONSTRAINT tendermilestone_pkey PRIMARY KEY (id);


--
-- Name: tendermilestonedocuments tendermilestonedocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_pkey PRIMARY KEY (id);


--
-- Name: user_contractingprocess user_contractingprocess_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_contractingprocess
    ADD CONSTRAINT user_contractingprocess_pkey PRIMARY KEY (id);


--
-- Name: award award_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.award
    ADD CONSTRAINT award_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awardamendmentchanges awardamendmentchanges_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awardamendmentchanges awardamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarddocuments awarddocuments_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarddocuments
    ADD CONSTRAINT awarddocuments_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awarddocuments awarddocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarddocuments
    ADD CONSTRAINT awarddocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarditem awarditem_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditem
    ADD CONSTRAINT awarditem_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awarditem awarditem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditem
    ADD CONSTRAINT awarditem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_awarditem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_awarditem_id_fkey FOREIGN KEY (awarditem_id) REFERENCES public.awarditem(id) ON DELETE CASCADE;


--
-- Name: awardsupplier awardsupplier_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardsupplier
    ADD CONSTRAINT awardsupplier_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awardsupplier awardsupplier_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardsupplier
    ADD CONSTRAINT awardsupplier_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: budget budget_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: budget budget_planning_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_planning_id_fkey FOREIGN KEY (planning_id) REFERENCES public.planning(id) ON DELETE CASCADE;


--
-- Name: clarificationmeeting clarificationmeeting_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeeting
    ADD CONSTRAINT clarificationmeeting_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: clarificationmeetingactor clarificationmeetingactor_clarificationmeeting_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_clarificationmeeting_id_fkey FOREIGN KEY (clarificationmeeting_id) REFERENCES public.clarificationmeeting(id) ON DELETE CASCADE;


--
-- Name: clarificationmeetingactor clarificationmeetingactor_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: contract contract_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract
    ADD CONSTRAINT contract_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractamendmentchanges contractamendmentchanges_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractamendmentchanges contractamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractdocuments contractdocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractdocuments
    ADD CONSTRAINT contractdocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractdocuments contractdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractdocuments
    ADD CONSTRAINT contractdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitem contractitem_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitem
    ADD CONSTRAINT contractitem_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractitem contractitem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitem
    ADD CONSTRAINT contractitem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contractitem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contractitem_id_fkey FOREIGN KEY (contractitem_id) REFERENCES public.contractitem(id) ON DELETE CASCADE;


--
-- Name: datapnt datapnt_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datapnt
    ADD CONSTRAINT datapnt_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementation implementation_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementation
    ADD CONSTRAINT implementation_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementation implementation_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementation
    ADD CONSTRAINT implementation_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: links links_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: memberof memberof_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberof
    ADD CONSTRAINT memberof_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: memberof memberof_principal_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberof
    ADD CONSTRAINT memberof_principal_parties_id_fkey FOREIGN KEY (principal_parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: parties parties_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parties
    ADD CONSTRAINT parties_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: planning planning_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning
    ADD CONSTRAINT planning_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: planningdocuments planningdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planningdocuments
    ADD CONSTRAINT planningdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: planningdocuments planningdocuments_planning_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planningdocuments
    ADD CONSTRAINT planningdocuments_planning_id_fkey FOREIGN KEY (planning_id) REFERENCES public.planning(id) ON DELETE CASCADE;


--
-- Name: publisher publisher_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publisher
    ADD CONSTRAINT publisher_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: quotes quotes_issuingsupplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_issuingsupplier_id_fkey FOREIGN KEY (issuingsupplier_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: quotes quotes_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES public.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: quotesitems quotesitems_quotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotesitems
    ADD CONSTRAINT quotesitems_quotes_id_fkey FOREIGN KEY (quotes_id) REFERENCES public.quotes(id) ON DELETE CASCADE;


--
-- Name: requestforquotes requestforquotes_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotes
    ADD CONSTRAINT requestforquotes_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id);


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES public.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: requestforquotesitems requestforquotesitems_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesitems
    ADD CONSTRAINT requestforquotesitems_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES public.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: roles roles_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: roles roles_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: tags tags_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tender tender_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tender
    ADD CONSTRAINT tender_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderamendmentchanges tenderamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderamendmentchanges tenderamendmentchanges_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tenderdocuments tenderdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderdocuments
    ADD CONSTRAINT tenderdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderdocuments tenderdocuments_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderdocuments
    ADD CONSTRAINT tenderdocuments_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tenderitem tenderitem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitem
    ADD CONSTRAINT tenderitem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderitem tenderitem_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitem
    ADD CONSTRAINT tenderitem_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_tenderitem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_tenderitem_id_fkey FOREIGN KEY (tenderitem_id) REFERENCES public.tenderitem(id) ON DELETE CASCADE;


--
-- Name: tendermilestone tendermilestone_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestone
    ADD CONSTRAINT tendermilestone_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tendermilestone tendermilestone_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestone
    ADD CONSTRAINT tendermilestone_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_milestone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_milestone_id_fkey FOREIGN KEY (milestone_id) REFERENCES public.tendermilestone(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: user_contractingprocess user_contractingprocess_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_contractingprocess
    ADD CONSTRAINT user_contractingprocess_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

GRANT ALL ON SCHEMA public TO prueba_captura;


--
-- PostgreSQL database dump complete
--

