-- View: public.view_mapa
CREATE OR REPLACE VIEW public.view_mapa
 AS
SELECT 
	DISTINCT on (id_project)
	p.id as id_project, p.title, p.identifier, epp.prefix, pt.title AS type, ps.title AS status, p.sector, ba.amount, pla.locality, plc.latitude, plc.longitude, pp."startDate"
FROM 
	public.edcapi_projects p, public.edcapi_project_location_projects plp, public.edcapi_location_projects lp, public.edcapi_budget_projects bp, public.edcapi_budget_amount_budgets bab, 
    public.edcapi_budget_amounts ba, public.edcapi_project_locations_coordinate_locations plcl, public.edcapi_project_location_coordinates plc, public.edcapi_project_locations_address_locations plal, 
    public.edcapi_project_location_addresses pla, public.edcapi_project_statuses ps ,public.edcapi_project_types pt,
	public.edcapi_project_periods pp, public.edcapi_project_period_projects ppp,
	public.edcapi_project_prefixes epp
WHERE 
	1 = 1
	AND p.is_public = true
	AND p.id = plp.project_id  
	AND p.id = bp.project_id
	AND bp."edcapiBudgetId" = bab.budget_id
	AND bab."edcapiBudgetAmountId" = ba.id
	AND plp.id = lp.id
	AND lp.id = plcl."edcapiLocationProjectId"
	AND plcl."edcapiProjectLocationCoordinateId" = plc.id
	AND lp.id = plal."edcapiLocationProjectId"
	AND plal."edcapiProjectLocationAddressId" = pla.id 
	AND p.status = ps.code
	AND p.type = pt.code
	AND p.id = ppp.project_id
	AND pp.id = ppp.project_period_id;

ALTER TABLE public.view_mapa
    OWNER TO prueba_captura;

GRANT ALL ON public.view_mapa TO prueba_captura;


-- View: public.view_total_awards_valueamount
CREATE OR REPLACE VIEW public.view_total_awards_valueamount
 AS
SELECT
	pt.partyid as rfc, round(coalesce(SUM(a.value_amount), 0)) as monto, COUNT(pt.partyid) as conteo, pxo.value as prefijoocid
FROM 
	public.edcapi_projects p, 
	public.edcapi_project_related_contracting_process_projects ercpp,
	public.edcapi_project_related_contracting_processes as eprcp,
	public.contractingprocess as cp,
	public.parties as pt,
	public.award as a,
	public.awardsupplier as sa,
	public.edcapi_project_periods pp,
	public.edcapi_project_period_projects ppp,
	public.prefixocid pxo
WHERE 
	1 = 1 
	AND p.is_public = true
	AND p.id = ercpp.project_id
	AND eprcp.id = ercpp."edcapiProjectRelatedContractingProcessId"
	AND cp.id = eprcp."contractingProcessId"
	AND cp.id = pt.contractingprocess_id
	AND a.contractingprocess_id = cp.id
	AND a.id = sa.award_id 
	AND sa.parties_id = pt.id
	AND p.id = ppp.project_id
	AND pp.id = ppp.project_period_id
GROUP BY 
	pt.partyid, prefijoocid;

ALTER TABLE public.view_total_awards_valueamount
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_awards_valueamount TO prueba_captura;


-- View: public.view_total_proyectos
CREATE OR REPLACE VIEW public.view_total_proyectos
 AS
SELECT 
	COUNT(*) AS totalprojects
FROM 
	public.edcapi_projects p
WHERE 
	1 = 1
	AND p.is_public = true;

ALTER TABLE public.view_total_proyectos
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_proyectos TO prueba_captura;


-- View: public.view_total_contrataciones
CREATE OR REPLACE VIEW public.view_total_contrataciones
 AS
SELECT 
	COUNT(*) AS totalcontractingprocess
FROM 
	public.edcapi_projects p, 
	public.edcapi_project_related_contracting_process_projects rcpp 
WHERE 
	1 = 1 
	AND p.is_public = true
	AND p.id = rcpp.project_id;

ALTER TABLE public.view_total_contrataciones
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_contrataciones TO prueba_captura;


-- View: public.view_total_contrataciones_buyer
CREATE OR REPLACE VIEW public.view_total_contrataciones_buyer
 AS
SELECT 
	count(cp.id) as contrataciones_institucion
FROM 
	public.edcapi_projects p, 
	public.edcapi_project_related_contracting_process_projects rcpp,
	public.edcapi_project_related_contracting_processes rcp,
	public.contractingprocess as cp,
	public.parties as pt,
	public.roles as r
WHERE 
	1 = 1 
	AND p.is_public = true
	AND p.id = rcpp.project_id
	AND rcp.id = rcpp."edcapiProjectRelatedContractingProcessId"
	AND rcp."contractingProcessId" = cp.id
	AND cp.id = pt.contractingprocess_id
	AND pt.id = r.parties_id
	AND r.buyer = true;

ALTER TABLE public.view_total_contrataciones_buyer
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_contrataciones_buyer TO prueba_captura;


-- View: public.view_total_contrataciones_buyer
CREATE OR REPLACE VIEW public.view_total_instituciones_publica
 AS
SELECT 
	COUNT (distinct (pt.identifier)) as publicAuthority
FROM 
	public.edcapi_projects p,
	public.edcapi_project_parties pt,
	public.edcapi_project_party_projects ppp,
	public.edcapi_project_parties_roles ppr,
	public.edcapi_project_parties_roles_parties pprp 
WHERE
	1 = 1
	AND p.is_public = true
	AND p.id = ppp.project_id
	AND pt.id = ppp."edcapiProjectPartyId"
	AND ppp."edcapiProjectPartyId" = pprp.party_id
	AND ppr.id = pprp."edcapiProjectPartiesRoleId"
	AND ppr."publicAuthority" = 'on';

ALTER TABLE public.view_total_instituciones_publica
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_instituciones_publica TO prueba_captura;


-- View: public.view_total_contrataciones_buyer
CREATE OR REPLACE VIEW public.view_total_instituciones_buyer
 AS
SELECT 
	COUNT (DISTINCT pt.partyid) AS buyers
FROM 
	public.edcapi_projects p, 
	public.edcapi_project_related_contracting_processes rcp, 
	public.edcapi_project_related_contracting_process_projects rcpp ,
	public.parties pt, 
	public.roles r
WHERE 
	1 = 1
	AND p.is_public = true
	AND p.id = rcpp.project_id
	AND rcp.id = rcpp."edcapiProjectRelatedContractingProcessId"
	AND rcp."contractingProcessId" = pt.contractingprocess_id
	AND pt.id = r.parties_id
	AND r.buyer = true;

ALTER TABLE public.view_total_instituciones_buyer
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_instituciones_buyer TO prueba_captura;


-- View: public.view_total_contratistas
CREATE OR REPLACE VIEW public.view_total_contratistas
 AS
SELECT 
	COUNT (DISTINCT pt.partyid) AS totalsuppliers
FROM 
	public.edcapi_projects p, 
	public.edcapi_project_related_contracting_processes rcp, 
	public.edcapi_project_related_contracting_process_projects rcpp ,
	public.parties pt, 
	public.roles r
WHERE 
	1 = 1
	AND p.is_public = true
	AND p.id = rcpp.project_id
	AND rcp.id = rcpp."edcapiProjectRelatedContractingProcessId"
	AND rcp."contractingProcessId" = pt.contractingprocess_id
	AND pt.id = r.parties_id
	AND r.supplier = true;

ALTER TABLE public.view_total_contratistas
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_contratistas TO prueba_captura;


-- View: public.view_total_licitantes
CREATE OR REPLACE VIEW public.view_total_licitantes
 AS
SELECT
	COUNT (distinct pt.partyid) AS totaltenderers
FROM 
	public.edcapi_projects p, 
	public.edcapi_project_related_contracting_processes rcp, 
	public.edcapi_project_related_contracting_process_projects rcpp ,
	public.parties pt, 
	public.roles r
WHERE 
	1 = 1
	AND p.is_public = true
	AND p.id = rcpp.project_id
	AND rcp.id = rcpp."edcapiProjectRelatedContractingProcessId"
	AND rcp."contractingProcessId" = pt.contractingprocess_id
	AND pt.id = r.parties_id
	AND r.tenderer = true;

ALTER TABLE public.view_total_licitantes
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_licitantes TO prueba_captura;


-- View: public.view_total_instituciones
CREATE OR REPLACE VIEW public.view_total_instituciones
 AS
SELECT 
		COUNT (distinct (pt.identifier)) as totalinstitutes
	FROM 
		public.edcapi_projects p,
		public.edcapi_project_parties pt,
		public.edcapi_project_party_projects ppp,
		public.edcapi_project_parties_roles ppr,
		public.edcapi_project_parties_roles_parties pprp 
	WHERE
		1 = 1
		AND p.is_public = true
		AND p.id = ppp.project_id
		AND pt.id = ppp."edcapiProjectPartyId"
		AND ppp."edcapiProjectPartyId" = pprp.party_id
		AND ppr.id = pprp."edcapiProjectPartiesRoleId"
		AND ppr."publicAuthority" = 'on';

ALTER TABLE public.view_total_instituciones
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_instituciones TO prueba_captura;


-- View: public.view_monto_total_proyectos
CREATE OR REPLACE VIEW public.view_monto_total_proyectos
 AS
SELECT 
	SUM (CAST (ba.amount as double precision)) as monto_total_proyectos
FROM 
	public.edcapi_projects p, 
	public.edcapi_budget_projects bp, 
	public.edcapi_budget_amount_budgets bab, 
    public.edcapi_budget_amounts ba
WHERE 
	1 = 1
	AND p.is_public = true
	AND p.id = bp.project_id
	AND bp."edcapiBudgetId" = bab.budget_id
	AND bab."edcapiBudgetAmountId" = ba.id; 

ALTER TABLE public.view_monto_total_proyectos
    OWNER TO prueba_captura;

GRANT ALL ON public.view_monto_total_proyectos TO prueba_captura;


-- View: public.view_monto_contratado_contrataciones
CREATE OR REPLACE VIEW public.view_monto_contratado_contrataciones
 AS
SELECT 
	SUM (c.value_amount) as monto_contratado
FROM 
	public.edcapi_projects p, 
	public.edcapi_project_related_contracting_process_projects rcpp, 
	public.edcapi_project_related_contracting_processes rcp,
	public.contract c
WHERE 
	1 = 1 
	AND p.is_public = true
	AND p.id = rcpp.project_id
	AND rcpp."edcapiProjectRelatedContractingProcessId" = rcp.id
	AND rcp."contractingProcessId" = c.contractingprocess_id;

ALTER TABLE public.view_monto_contratado_contrataciones
    OWNER TO prueba_captura;

GRANT ALL ON public.view_monto_contratado_contrataciones TO prueba_captura;


-- View: public.view_monto_ejercido_contrataciones
CREATE OR REPLACE VIEW public.view_monto_ejercido_contrataciones
 AS
SELECT 
	SUM (it.value_amount) as monto_ejercido
FROM 
	public.edcapi_projects p,
	public.edcapi_project_periods pp, 
	public.edcapi_project_period_projects ppp,
	public.edcapi_project_related_contracting_process_projects rcpp, 
	public.edcapi_project_related_contracting_processes rcp,
	public.contract c,
	public.implementation i,
	public.implementationtransactions it
WHERE 
	1 = 1 
	AND p.is_public = true
	AND p.id = rcpp.project_id
	AND rcpp."edcapiProjectRelatedContractingProcessId" = rcp.id
	AND rcp."contractingProcessId" = c.contractingprocess_id
	AND c.id = i.contract_id
	AND i.id = it.implementation_id
	AND p.id = ppp.project_id
	AND pp.id = ppp.project_period_id;

ALTER TABLE public.view_monto_ejercido_contrataciones
    OWNER TO prueba_captura;

GRANT ALL ON public.view_monto_ejercido_contrataciones TO prueba_captura;


-- View: public.view_info_proyectos
CREATE OR REPLACE VIEW public.view_info_proyectos
 AS
SELECT 
	DISTINCT p.id,p.oc4ids,p.identifier,p.updated,p.title, epp.identifier as rfc, epp.name as publicAuthority,
	ba.amount as monto,ba.currency as moneda_budget, p.sector,pt.title AS type,pp."startDate",pp."endDate",ps.title AS status
FROM 
	public.edcapi_projects p,
	public.edcapi_budget_projects bp, 
	public.edcapi_budget_amount_budgets bab, 
    public.edcapi_budget_amounts ba,
	public.edcapi_project_statuses ps,
	public.edcapi_project_types pt,
	public.edcapi_project_periods pp, 
	public.edcapi_project_period_projects ppp,
	public.edcapi_project_party_projects pparty,
	public.edcapi_project_parties epp,
	public.edcapi_project_parties_roles ppr,
    public.edcapi_project_parties_roles_parties pprp 
WHERE 
	1 = 1
	AND p.is_public = true
	AND p.id = bp.project_id
	AND bp."edcapiBudgetId" = bab.budget_id
	AND bab."edcapiBudgetAmountId" = ba.id 
	AND p.status = ps.code
	AND p.type = pt.code
	AND p.id = ppp.project_id
	AND pp.id = ppp.project_period_id
	AND p.id = ppp.project_id
	AND pparty.project_id = p.id
	AND pparty."edcapiProjectPartyId" = pprp.party_id
	AND pparty."edcapiProjectPartyId" = epp.id
	AND ppr.id = pprp."edcapiProjectPartiesRoleId"
	AND ppr."publicAuthority" = 'on'
ORDER BY
	p.id;

ALTER TABLE public.view_info_proyectos
    OWNER TO prueba_captura;

GRANT ALL ON public.view_info_proyectos TO prueba_captura;


-- View: public.view_info_instituciones
CREATE OR REPLACE VIEW public.view_info_instituciones
 AS
SELECT 
	distinct on (publicAuthority)
	p.id, pt.identifier as publicAuthority, pt.name, pcp.name as contactName, pcp.url as contactURL, 
	(SELECT 
		count (ept.identifier) as conteoProyectos
	FROM 
		public.edcapi_project_parties ept
	WHERE
		ept.identifier = pt.identifier
	group by
		ept.identifier, ept.name
	limit 1),
	(SELECT 
		count(p.id) as totalContrataciones
	FROM 
		public.edcapi_projects p,
		public.edcapi_project_parties ptis,
		public.edcapi_project_party_projects ppp,
		public.edcapi_project_parties_roles ppr,
		public.edcapi_project_parties_roles_parties pprp,
		public.edcapi_project_related_contracting_process_projects rcpp
	WHERE
		1 = 1
		AND p.is_public = true
		AND p.id = ppp.project_id
		AND ptis.id = ppp."edcapiProjectPartyId"
		AND ppp."edcapiProjectPartyId" = pprp.party_id
		AND ppr.id = pprp."edcapiProjectPartiesRoleId"
		AND p.id = rcpp.project_id
	 AND pt.identifier = ptis.identifier
		AND ppr."publicAuthority" = 'on'),
	(SELECT 
		coalesce(sum(it.value_amount), 0) montoejercido
	FROM 
		public.edcapi_projects ep,
		public.edcapi_project_parties ptis,
		public.edcapi_project_party_projects ppp,
		public.edcapi_project_parties_roles ppr,
		public.edcapi_project_parties_roles_parties pprp,
		public.edcapi_project_related_contracting_process_projects rcpp,
		public.edcapi_project_related_contracting_processes eprcp,
		public.implementationtransactions it
	WHERE
		1 = 1
		AND ep.is_public = true
		AND ep.id = ppp.project_id
		AND ptis.id = ppp."edcapiProjectPartyId"
		AND ppp."edcapiProjectPartyId" = pprp.party_id
		AND ppr.id = pprp."edcapiProjectPartiesRoleId"
		AND ep.id = rcpp.project_id
		AND eprcp.id = rcpp."edcapiProjectRelatedContractingProcessId"
		AND eprcp."contractingProcessId" = it.contractingprocess_id
		AND ppr."publicAuthority" = 'on'
	 	AND ptis.identifier = pt.identifier
	group by
	 ptis.identifier),
	eppfxs.prefix as prefijooc4id, pp."startDate", pp."endDate"
FROM 
	public.edcapi_projects p,
	public.edcapi_project_parties pt,
	public.edcapi_project_party_projects ppp,
	public.edcapi_project_parties_roles ppr,
	public.edcapi_project_parties_roles_parties pprp,
	public.edcapi_project_parties_contact_point_parties as pcpp,
	public.edcapi_project_parties_contact_points pcp,
	public.edcapi_project_periods pp, 
	public.edcapi_project_period_projects eppp,
	public.edcapi_project_prefixes eppfxs
WHERE
	1 = 1
	AND p.is_public = true
	AND p.id = ppp.project_id
	AND pt.id = ppp."edcapiProjectPartyId"
	AND ppp."edcapiProjectPartyId" = pprp.party_id
	AND ppr.id = pprp."edcapiProjectPartiesRoleId"
	AND pt.id = pcpp.party_id
	AND pcp.id = pcpp."edcapiProjectPartiesContactPointId"
	AND ppr."publicAuthority" = 'on'
 	AND p.id = eppp.project_id
	AND pp.id = eppp.project_period_id
GROUP BY 
	p.id, publicAuthority, pt.name, contactName, contactURL, eppfxs.prefix, pp."startDate", pp."endDate";

ALTER TABLE public.view_info_instituciones
    OWNER TO prueba_captura;	

GRANT ALL ON public.view_info_instituciones TO prueba_captura;


-- View: public.view_info_contrataciones
CREATE OR REPLACE VIEW public.view_info_contrataciones
 AS
SELECT
DISTINCT 
	ep.id, ep.identifier as identificadorProyecto, ep.title as title_proyectos, eprcp."contractingProcessId", eprcp.ocid, cp.ocid as idcontratacion,
	cp.updated_date,t.status as tenderstatus, cp.awardstatus, cp.contractstatus, cp.implementationstatus,
	t.title as title_contratacion, pxo.value as prefijoocid, replace(tenderid,'/','-') as tenderid, pp."startDate",
	(select
		exists (select * from public.view_info_instituciones as pru where pru.publicauthority = p.partyid) as registroedcapi
		from 
			public.parties as p,
			public.roles as r
		where 
			1=1
			AND r.parties_id = p.id
			AND (r.buyer = true)
			AND eprcp."contractingProcessId" = cp.id  
			AND r.contractingprocess_id = eprcp."contractingProcessId"),
	(select
			p.id as id_institucion
		from 
			public.parties as p,
			public.roles as r
		where 
			1=1
			AND r.parties_id = p.id
			AND (r.buyer = true)
			AND eprcp."contractingProcessId" = cp.id  
	 		AND r.contractingprocess_id = eprcp."contractingProcessId"
	 limit 1),
	 (select
			p.id as id_contratista
		from 
			public.parties as p,
			public.roles as r
		where 
			1=1
			AND r.parties_id = p.id
			AND (r.supplier = true)
			AND eprcp."contractingProcessId" = cp.id  
	 		AND r.contractingprocess_id = eprcp."contractingProcessId"
	 limit 1),
	 (select
			p.partyid as rfc_buyer
		from 
			public.parties as p,
			public.roles as r
		where 
			1=1
			AND r.parties_id = p.id
			AND (r.buyer = true)
			AND eprcp."contractingProcessId" = cp.id  
	 		AND r.contractingprocess_id = eprcp."contractingProcessId"
	 limit 1),
	(select
			p.name as name_buyer
		from 
			public.parties as p,
			public.roles as r
		where 
			1=1
			AND r.parties_id = p.id
			AND (r.buyer = true)
			AND eprcp."contractingProcessId" = cp.id  
	 		AND r.contractingprocess_id = eprcp."contractingProcessId"
	 limit 1),
	 (select
			round(coalesce(SUM(c.exchangerate_amount), 0)) as monto
		from 
			public.contract as c
		where 
			1=1
	  	AND c.contractingprocess_id = eprcp."contractingProcessId"
	 )
FROM
	public.edcapi_projects as ep,
	public.edcapi_project_related_contracting_process_projects as eprcpp,
	public.edcapi_project_related_contracting_processes as eprcp,
	public.contractingprocess as cp,
	public.tender t,
	public.edcapi_project_periods pp,
	public.edcapi_project_period_projects ppp,
	public.prefixocid pxo
WHERE
	1 = 1
	AND ep.is_public = true
	AND eprcpp.project_id = ep.id
	AND eprcp.id = eprcpp."edcapiProjectRelatedContractingProcessId"
	AND cp.id = eprcp."contractingProcessId"	
	AND t.contractingprocess_id = eprcp."contractingProcessId"
	AND ep.id = ppp.project_id
	AND pp.id = ppp.project_period_id
ORDER BY
	ep.id ASC;

ALTER TABLE public.view_info_contrataciones
    OWNER TO prueba_captura;

GRANT ALL ON public.view_info_contrataciones TO prueba_captura;


-- View: public.view_info_contratistas
CREATE OR REPLACE VIEW public.view_info_contratistas
 AS
SELECT
DISTINCT on (rfc)
	p.id, cp.id as cp_id, pxo.value as prefijoocid, pt.partyid as rfc, name, address_locality, address_region, address_postalcode, contactpoint_url, pp."startDate",
	vtav.monto
FROM 
	public.edcapi_projects p, 
	public.edcapi_project_related_contracting_process_projects ercpp,
	public.edcapi_project_related_contracting_processes as eprcp,
	public.contractingprocess as cp,
	public.parties as pt,
	public.award as a,
	public.awardsupplier as sa,
	public.edcapi_project_periods pp,
	public.edcapi_project_period_projects ppp,
	public.prefixocid pxo,
	public.view_total_awards_valueamount vtav
WHERE 
	1 = 1 
	AND p.is_public = true
	AND p.id = ercpp.project_id
	AND eprcp.id = ercpp."edcapiProjectRelatedContractingProcessId"
	AND cp.id = eprcp."contractingProcessId"
	AND cp.id = pt.contractingprocess_id
	AND a.contractingprocess_id = cp.id
	AND a.id = sa.award_id 
	AND sa.parties_id = pt.id
	AND p.id = ppp.project_id
	AND pp.id = ppp.project_period_id
	AND vtav.rfc = pt.partyid
ORDER BY 
	pt.partyid;

ALTER TABLE public.view_info_contratistas
    OWNER TO prueba_captura;

GRANT ALL ON public.view_info_contratistas TO prueba_captura;


-- View: public.view_total_status_proyectos
CREATE OR REPLACE VIEW public.view_total_status_proyectos
AS
SELECT 
	p.status, count(p.status) as total_estatus
FROM 
	public.edcapi_projects p
WHERE 
	1 = 1
	AND p.is_public = true
GROUP BY p.status;

ALTER TABLE public.view_total_status_proyectos
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_status_proyectos TO prueba_captura;


-- View: public.view_info_contratistas_listas
CREATE OR REPLACE VIEW public.view_info_contratistas_listas
AS
SELECT
	pt.contractingprocess_id, pxo.value as prefijoocid, pt.partyid, pt."name", pp."startDate"
FROM 
	public.edcapi_projects p, 
	public.edcapi_project_related_contracting_processes rcp, 
	public.edcapi_project_related_contracting_process_projects rcpp,
	public.parties pt, 
	public.roles r,
	public.edcapi_project_periods pp, 
	public.edcapi_project_period_projects ppp,
	public.prefixocid pxo
WHERE 
	1 = 1
	AND p.is_public = true
	AND p.id = rcpp.project_id
	AND rcp.id = rcpp."edcapiProjectRelatedContractingProcessId"
	AND rcp."contractingProcessId" = pt.contractingprocess_id
	AND pt.id = r.parties_id
	AND p.id = ppp.project_id
	AND pp.id = ppp.project_period_id
	AND p.id = ppp.project_id
	AND r.supplier = true;

ALTER TABLE public.view_info_contratistas_listas
    OWNER TO prueba_captura;

GRANT ALL ON public.view_info_contratistas_listas TO prueba_captura;


-- View: public.view_total_indicadores
CREATE OR REPLACE VIEW public.view_total_indicadores
AS
SELECT 
	p.id as proyecto_id, p.status, count(p.status) as total_estatus, sum(eba.amount) as monto, eba.currency, 
	extract(year from (TO_TIMESTAMP( "startDate", 'YYYY-MM-DD HH24:MI:SS' ))) as yearproyecto
FROM
	public.edcapi_budget_amounts as eba,
	public.edcapi_projects p,
	public.edcapi_project_periods pp, 
	public.edcapi_project_period_projects ppp
WHERE
	1=1
	AND p.is_public = true
	AND p.id = eba.id
	AND p.id = ppp.project_id
	AND pp.id = ppp.project_id
GROUP BY 
	p.id, p.status, ppp.project_id, eba.currency, pp."startDate"
ORDER BY
	p.id;

ALTER TABLE public.view_total_indicadores
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_indicadores TO prueba_captura;


-- View: public.view_total_indicadores_contrataciones
CREATE OR REPLACE VIEW public.view_total_indicadores_contrataciones
AS
SELECT
DISTINCT 
	eprcp."contractingProcessId", t.status as statustender, cp.awardstatus as statusaward, cp.contractstatus as statuscontract, 
	cp.implementationstatus as statusimplementation, t.procurementmethod_details as detalleprocedimiento, sum(exchangerate_amount) as monto, pxo.value as prefijoocid, pp."startDate"
FROM
	public.edcapi_projects as ep,
	public.edcapi_project_related_contracting_process_projects as eprcpp,
	public.edcapi_project_related_contracting_processes as eprcp,
	public.contractingprocess as cp,
	public.tender t,
	public.edcapi_project_periods pp,
	public.edcapi_project_period_projects ppp,
	public.prefixocid pxo,
	public.contract c
WHERE
	1 = 1
	AND ep.is_public = true
	AND eprcpp.project_id = ep.id
	AND eprcp.id = eprcpp."edcapiProjectRelatedContractingProcessId"
	AND cp.id = eprcp."contractingProcessId"	
	AND t.contractingprocess_id = eprcp."contractingProcessId"
	AND ep.id = ppp.project_id
	AND pp.id = ppp.project_period_id
	AND c.contractingprocess_id = eprcp."contractingProcessId"
GROUP BY
	eprcp."contractingProcessId", t.status, cp.awardstatus, cp.contractstatus, cp.implementationstatus, pxo.value, t.procurementmethod_details, pp."startDate";
	
ALTER TABLE public.view_total_indicadores_contrataciones
    OWNER TO prueba_captura;

GRANT ALL ON public.view_total_indicadores_contrataciones TO prueba_captura;


-- View: public.view_desglose_presupuesto_proyecto
CREATE OR REPLACE VIEW public.view_desglose_presupuesto_proyecto
 AS
SELECT  
		p.id, p.identifier, 
		(year||coalesce("kBranch",'')||coalesce("kResponsibleUnit",'')||coalesce("kFinality",'')||coalesce("kFunction",'')||
		coalesce("kSubFunction",'')||coalesce("kInstAct",'')||coalesce("kBudgetProgram",'')||coalesce("kSpendingObject",'')||
		coalesce("kSpendingType",'')||coalesce("kBudgetSource",'')||coalesce("kRegion",'')||coalesce("kPortfolio",'')) 
		as clavepresupuestaria, 
		pbbsp."name", pbb.amount, pbb.currency
	FROM 
		public.edcapi_projects as p,
		public.edcapi_project_budget_breakdowns as pbb,
		public.edcapi_project_budget_breakdown_budgets as pbbb,
		public.edcapi_project_budget_breakdown_source_parties as pbbsp,
		public.edcapi_project_budget_breakdown_budget_lines_components epbbblc,
		public.edcapi_project_budget_breakdown_budget_lines_component_budgets epbbblcb,
		public.edcapi_project_budget_breakdown_budget_line_budgets epbbblb
	WHERE 
		1=1
		AND p.is_public = true
		AND p.id = pbbsp.project_id
		AND pbbb.id = pbbsp.id
		AND pbbb.id = pbb.id
		AND epbbblcb."edcapiProjectBudgetBreakdownBudgetLineId" = epbbblb."edcapiProjectBudgetBreakdownBudgetLineId"
		AND epbbblb."edcapiProjectBudgetBreakdownId" = pbbb."edcapiProjectBudgetBreakdownId"
		AND epbbblc.id = epbbblcb.id;
		
ALTER TABLE public.view_desglose_presupuesto_proyecto
    OWNER TO prueba_captura;

GRANT ALL ON public.view_desglose_presupuesto_proyecto TO prueba_captura;


-- View: public.view_public_authority_registered
CREATE OR REPLACE VIEW public.view_public_authority_registered
 AS
SELECT eppp.project_id, epp.identifier, epp.name, eppr."publicAuthority" as publicauthorityon, eppp."edcapiProjectPartyId" as edcapiProjectPartyIdon
	FROM
		public.edcapi_project_parties epp,
		public.edcapi_project_parties_roles eppr,
		public.edcapi_project_party_projects eppp
	WHERE
		1=1
		AND epp.id = eppr.id
		AND epp.id = eppp."edcapiProjectPartyId"
		AND eppr."publicAuthority" = 'on';
				
ALTER TABLE public.view_public_authority_registered
    OWNER TO prueba_captura;

GRANT ALL ON public.view_public_authority_registered TO prueba_captura;


-- View: public.view_public_contractingprocesses_registered
CREATE OR REPLACE VIEW public.view_public_contractingprocesses_registered
 AS
SELECT eprcpp."edcapiProjectRelatedContractingProcessId" as eprcontractingprocessid, eprcpp.project_id, eprcp.id, eprcp."contractingProcessId" as contractingprocessid, eprcp.ocid
	FROM 
		public.edcapi_project_related_contracting_process_projects eprcpp,
		public.edcapi_project_related_contracting_processes eprcp
	WHERE
		1=1
		AND eprcpp."edcapiProjectRelatedContractingProcessId" = eprcp.id;
				
ALTER TABLE public.view_public_contractingprocesses_registered
    OWNER TO prueba_captura;

GRANT ALL ON public.view_public_contractingprocesses_registered TO prueba_captura;