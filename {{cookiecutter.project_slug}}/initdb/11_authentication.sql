begin;

--------------------------------------------------------------------------------
-- We use JSON Web Tokens to authenticate API requests.
-- PostgREST cares specifically about a claim called role.
-- When a request contains a valid JWT with a role claim PostgREST
-- will switch to the database role with that name for the duration
-- of the HTTP request. If the client included no (or an invalid) JWT
-- then PostgREST selects the role "anonymous".

create role anonymous;
create role author;
grant anonymous, author to authenticator;
grant usage on schema public to anonymous, author;

--------------------------------------------------------------------------------
-- The user id is a string stored in postgrest.claims.sub.

create function current_user_id() returns text
stable
language plpgsql
as $$
begin
	return current_setting('postgrest.claims.userid');
exception
	-- handle unrecognized configuration parameter error
	when undefined_object then return '';
end;
$$;

grant execute on function current_user_id() to anonymous, author;

--------------------------------------------------------------------------------
-- We put things inside a separate schema to hide them from public view.
-- Certain public procs/views will refer to helpers and tables inside.

create schema auth;

create table auth.users (
	id            text      primary key,
	created       timestamp not null default now(),
	last_login    timestamp not null default now(),
	name          text      not null,
    email         text      not null,
	profile       json
);

--------------------------------------------------------------------------------
-- RPC to upsert the current user's profile.

create function login(user_profile json) returns void
language sql
security definer
as $$
	insert into auth.users (id, last_login, name, email, profile)
	values (
        current_user_id(),
        now(),
        user_profile::json->>'name',
        user_profile::json->>'email',
        user_profile
    )
	on conflict (id) do update set (last_login, name, email, profile) =
        (excluded.last_login, excluded.name, excluded.email, excluded.profile);
$$;

grant execute on function login(json) to author;

commit;
