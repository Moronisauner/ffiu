## Abordagens
    - triggers + notifications
    - triggers + tabela de eventos
    - pg_sync

### triggers + notifications

A ideia aqui é usar o pub/sub nativo parar publicar e consumir as mensagens que indicam um `insert`, `update` ou `delete` dos registros nas tabelas.
Para isso precisamos de uma função que dispare a mensagens em algum canal conhecido e a mensagens precisa ter a linha que foi inserida/editara/deletada.

#### A função
```sql
create or replace function fn_notify_event ()
returns trigger
language plpgsql as
$$
declare
    message jsonb;
begin
    if TG_OP = 'DELETE' then
        select json_build_object('action', TG_OP, 'row', row_to_json(OLD)) into message;
    else
        select json_build_object('action', TG_OP, 'row', row_to_json(NEW)) into message;
    end if;

    execute 'notify tb_' || TG_TABLE_NAME || ', ''' || message || ''';' ;

    return null;
end;
$$
```

#### O trigger
```sql
create trigger tg_notify_events
after insert or update or delete
on table1
for each row
execute procedure fn_notify();
```

A vantagem dessa abordagem é que teremos uma mensagem sendo enviada pelo canal específico pra tabela ou algum canal fixo pra todas as tabelas.
Dando a possibilidade de receber a mensagem e fazer qualquer tipo de tratamento. Seja esse tratamento a criação de um registro em outra tabela, o mapeamento que planejamos ou ainda fisparar uma sequência de tratamentos.
Isso viabiliza mantar 2 bancos sincronizados e permite usar a chegada das mensagens para disparar algum job.

A desvantagem dessa abordagem é que diferente do rabbitmq, as mensagens são perdidas caso não tenha ninguém escutando o canal.

### triggers + tabela de eventos
A parte dos triggers seria semelhante demonstrado acima. Com a diferença de que não enviaremos uma mensagem pro canal, mas sim registraremos um registro numa tabela com os eventos.

A vantagem é que igualmente podemos manter a sincronia e possibilita disparar jobs com as mensagens novas. Também garante que não perderemos mensagens independente de ter alguma aplicação escutando o canal.
A desvantagem é que precisa de um pooler pra consultar as mensagens novas. Isso insere um delay que não existiria com o esquema de pub/sub.
Também será necessário adiministrar uma tabela nova que tem potencial de crescer bastante. Ainda assim não acredito que isso se tornaria um desafio grande para resolver. Podemos deletar eventos antigos por exemplo.

#### A tabela
```sql
CREATE TABLE sync_events (
	id bigserial NOT NULL,
	"row" jsonb NOT NULL,
	table varchar(255) NOT NULL,
	command varchar(255) NOT NULL,
	received bool NULL DEFAULT false,
	inserted_at timestamp(0) NOT NULL,
	updated_at timestamp(0) NOT NULL,
	CONSTRAINT sync_events_pkey PRIMARY KEY (id)
);
```

#### A função
```sql
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

    insert into sync_events(from_table, command, "row", inserted_at, updated_at) values (TG_TABLE_NAME, TG_OP, message, now(), now());

    return null;
end;
$$
```

#### O trigger
```sql
create trigger tg_save_operations
after insert or update or delete 
on table1
for each row
execute procedure  fn_save_notification();
```

Vale acrescentar que é importante consumir os eventos em ordem. Para garantir a ordem correta estou usando o id serial que pode ser usado para garantir a ordem.
Mais uma coisa interessante é que podemos fazer um esquema para marcar como `received` apenas as mensagens que puderem ser consumidas corretamente.
Na POC que preparei inclusive se existir uma mensagem referente a uma tabela que o consumidor não sabe o que fazer o consumo das mensagens é interrompido. O consumidor vai sempre retentar consumir o evento e não consumirá novos até que se resolva o problema.
