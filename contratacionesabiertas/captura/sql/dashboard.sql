-- clonar esquema para el dashboard
\c edca

Create schema dashboard;

SELECT public.clone_schema('public', 'dashboard');


ALTER ROLE prueba_dashboard SET search_path TO dashboard;
