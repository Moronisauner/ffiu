defmodule Ffiu.Repo.Migrations.CreateNotifications do
  @moduledoc """
  Declaramos aqui uma função que prepara uma mensagem e envia para um channel definido pelo nome da tabela de onde o trigger foi disparado.
  """

  use Ecto.Migration

  def up do
    execute("""
    create or replace function fn_notify_test ()
    returns trigger
    language plpgsql as
    $$
    declare
      table_name text := TG_TABLE_NAME;
      op text := TG_OP;
      message jsonb;
    begin
      if op = 'DELETE' then
        select json_build_object('action', op, 'row', row_to_json(OLD)) into message;
      else
        select json_build_object('action', op, 'row', row_to_json(NEW)) into message;
      end if;

      execute 'notify tb_' || table_name || ', ''' || message || ''';' ;

      return null;
    end;
    $$
    """)

    execute("""
    create trigger tg_notify_table1
    after insert or update or delete
    on table1
    for each row
    execute procedure fn_notify_test();
    """)
  end

  def down do
    execute("DROP FUNCTION fn_notify_test();")
    execute("DROP TRIGGER tg_notify_table1 ON table1;")
  end
end
