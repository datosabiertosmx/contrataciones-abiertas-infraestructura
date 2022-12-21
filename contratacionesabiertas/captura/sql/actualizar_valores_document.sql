-- Actualizar el valor del campo languaje para envío del código del idioma en el JSON

update public.planningdocuments set language='es' where language='Spanish; Castilian';
update public.tenderdocuments set language='es' where language='Spanish; Castilian';
update public.awarddocuments set language='es' where language='Spanish; Castilian';
update public.contractdocuments set language='es' where language='Spanish; Castilian';
update public.implementationdocuments set language='es' where language='Spanish; Castilian';