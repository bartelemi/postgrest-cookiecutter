-- Content Secure Policy report.

begin;

create table auth.csp_reports (
	id            bigserial primary key,
	created       timestamp not null default now(),
	report        jsonb     not null
);

create function csp_report("csp-report" json) returns void
language sql
security definer
as $$
	insert into auth.csp_reports (report)
	values ("csp-report")
$$;

grant execute on function csp_report(json) to anonymous;

commit;
