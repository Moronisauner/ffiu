defmodule Ffiu.Repo.Migrations.CreateSyncFunction do
  use Ecto.Migration

  def up do
    execute("""
    create or replace function fn_save_notification ()
    returns trigger
    language plpgsql as
    $$
    declare
      message jsonb;
    begin
      if TG_OP = 'DELETE' then
        select row_to_json(OLD) into message;
      else
        select row_to_json(NEW) into message;
      end if;

      insert into sync_events(table, command, "row", inserted_at, updated_at) values (TG_TABLE_NAME, TG_OP, message, now(), now());

      return null;
    end;
    $$
    """)
  end

  def down do
    execute("DROP FUNCTION fn_save_notification;")
  end
end
