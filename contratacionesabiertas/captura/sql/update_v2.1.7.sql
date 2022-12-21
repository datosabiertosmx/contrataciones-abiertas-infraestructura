-- Update versión 2.1.7 (jul-2022)

-- Etapa Planeación - Formulario Líneas presupuestarias
alter table public.budgetclassifications add column branch_description text;
alter table dashboard.budgetclassifications add column branch_description text;

alter table public.budgetclassifications add column responsibleunit_description text;
alter table dashboard.budgetclassifications add column responsibleunit_description text;

alter table public.budgetclassifications add column finality_description text;
alter table dashboard.budgetclassifications add column finality_description text;

alter table public.budgetclassifications add column function_description text;
alter table dashboard.budgetclassifications add column function_description text;

alter table public.budgetclassifications add column subfunction_description text;
alter table dashboard.budgetclassifications add column subfunction_description text;

alter table public.budgetclassifications add column institutionalactivity_description text;
alter table dashboard.budgetclassifications add column institutionalactivity_description text;

alter table public.budgetclassifications add column budgetprogram_description text;
alter table dashboard.budgetclassifications add column budgetprogram_description text;

alter table public.budgetclassifications add column spendingobject_description text;
alter table dashboard.budgetclassifications add column spendingobject_description text;

alter table public.budgetclassifications add column spendingtype_description text;
alter table dashboard.budgetclassifications add column spendingtype_description text;

alter table public.budgetclassifications add column budgetsource_description text;
alter table dashboard.budgetclassifications add column budgetsource_description text;

alter table public.budgetclassifications add column region_description text;
alter table dashboard.budgetclassifications add column region_description text;

alter table public.budgetclassifications add column portfoliokey_description text;
alter table dashboard.budgetclassifications add column portfoliokey_description text;