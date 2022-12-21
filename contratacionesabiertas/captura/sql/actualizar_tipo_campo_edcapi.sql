-- Cambiar el tipo de campo de la tabla de momentos presupuestarios

alter table public.edcapi_project_budget_breakdown_budget_lines_measures alter column amount type varchar(255);

-- Cambiar el tipo de campo de la tabla proyectos

alter table public.edcapi_projects alter column purpose type text;

-- Cambiar el tipo de campo de la tabla de budget amounts

alter table public.edcapi_budget_amounts alter column amount type numeric USING amount::numeric;

-- Cambiar el tipo de campo de la tabla edcapi_project_period

alter table public.edcapi_project_periods alter column "startDate" type varchar(255);
alter table public.edcapi_project_periods alter column "endDate" type varchar(255);
alter table public.edcapi_project_periods alter column "maxExtentDate" type varchar(255);