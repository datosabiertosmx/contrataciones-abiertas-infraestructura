-- Update versión 2.1.5 (jun-2021)

-- Etapa Licitación
alter table public.tender add column procedurecharacter text;
alter table dashboard.tender add column procedurecharacter text;

-- Formulario Actores 
alter table public.parties add address_typeofroad text;
alter table dashboard.parties add address_typeofroad text;

alter table public.parties add address_outdoornumber text;
alter table dashboard.parties add address_outdoornumber text;

alter table public.parties add address_interiornumber text;
alter table dashboard.parties add address_interiornumber text;

alter table public.parties add address_typeofsettlement text;
alter table dashboard.parties add address_typeofsettlement text;

alter table public.parties add address_settlementname text;
alter table dashboard.parties add address_settlementname text;

alter table public.parties add address_locationname text;
alter table dashboard.parties add address_locationname text;

alter table public.parties add address_regionkey text;
alter table dashboard.parties add address_regionkey text;

alter table public.parties add address_alcaldiakey text;
alter table dashboard.parties add address_alcaldiakey text;

alter table public.parties add address_localitykey text;
alter table dashboard.parties add address_localitykey text;

alter table public.parties add address_streetabroad text;
alter table dashboard.parties add address_streetabroad text;

alter table public.parties add address_numberabroad text;
alter table dashboard.parties add address_numberabroad text;

alter table public.parties add address_cityabroad text;
alter table dashboard.parties add address_cityabroad text;

alter table public.parties add address_countryabroad text;
alter table dashboard.parties add address_countryabroad text;