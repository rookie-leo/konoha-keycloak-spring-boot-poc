# Portal de Konoha

Prova de conceito para estudar autenticação e autorização com **Keycloak, Spring Boot e PostgreSQL**. A pergunta que guia o projeto é simples: como o portal identifica o ninja que entrou e decide quais missões ele pode acessar?

O estudo surgiu de uma demanda sobre o **Red Hat build of Keycloak (RHBK)**. Para facilitar a reprodução local, a PoC usa a imagem pública do Keycloak da comunidade.

## Escopo da PoC

| Etapa | O que quero demonstrar |
|---|---|
| 1. Ambiente local | Subir Keycloak e PostgreSQL com Docker Compose e carregar os ninjas de teste por SQL. |
| 2. Login OIDC | Entrar no portal Spring Boot como Naruto, cadastrado diretamente no Keycloak, e ver `naruto.uzumaki` em `/me`. |
| 3. Federação de usuários | Entrar na mesma página como Sakura, usando a conta da Academia Ninja armazenada no PostgreSQL. |
| 4. Autorização | Proteger uma missão por patente e verificar como uma promoção muda o acesso após um novo login. |

O Compose e o seed formam a primeira etapa. O realm `konoha`, o cliente OIDC, o portal Spring Boot, o provider de usuários e as regras de missão serão implementados ao longo do estudo.

## Como subir o ambiente

Com o Docker e o Docker Compose instalados, execute na raiz do repositório:

~~~sh
docker compose up -d
docker compose ps -a
~~~

O serviço `postgres` deve ficar saudável. O serviço `seed` executa o arquivo `konoha.sql` e termina com código `0`. Esse é o resultado esperado: a tarefa dele é preparar o banco. Em seguida, o serviço `rhbk` inicia o Keycloak da comunidade.

Acesse o [console administrativo local](http://localhost:8081/admin/) com o usuário `admin` e a senha `admin-local`. O primeiro exercício é criar manualmente o realm `konoha`.

Para conferir os dados da Academia:

~~~sh
docker compose exec postgres psql -U postgres -d academia_ninja -c "SELECT username, patente FROM ninja ORDER BY id;"
~~~

Para encerrar o ambiente e manter os dados para a próxima sessão:

~~~sh
docker compose down
~~~

## Ninjas disponíveis

| Ninja | Usuário | Patente na PoC | Origem da conta |
|---|---|---|---|
| Konohamaru Sarutobi | `konohamaru.sarutobi` | Genin | Seed PostgreSQL |
| Sakura Haruno | `sakura.haruno` | Chunin | Seed PostgreSQL |
| Kakashi Hatake | `kakashi.hatake` | Jonin | Seed PostgreSQL |
| Tsunade | `tsunade` | Hokage | Seed PostgreSQL |
| Naruto Uzumaki | `naruto.uzumaki` | Genin | Cadastro manual no Keycloak, na etapa 2 |

A senha inicial dos quatro usuários do seed é `konoha-local`, armazenada como hash bcrypt. A senha de Naruto será definida no cadastro manual. O seed pode rodar novamente e preserva alterações de senha e patente dos usuários existentes.

## Como as peças se conectam

O PostgreSQL hospeda dois bancos com responsabilidades diferentes:

- **`rhbk`** guarda os dados administrados pelo Keycloak, como realms, clientes e contas locais. É onde ficará o cadastro de Naruto.
- **`academia_ninja`** contém a tabela `ninja`, que representa um cadastro externo já existente. É onde está a conta de Sakura.

Na etapa de **autenticação**, o navegador abre `/me` no Spring Boot e é redirecionado ao Keycloak. Para Naruto, o Keycloak valida a conta local. Para Sakura, o **User Storage Provider** deverá buscar a conta na Academia e verificar a senha. Nos dois casos, o portal recebe a identidade pelo mesmo fluxo OIDC, o *Authorization Code*.

Na etapa de **autorização**, a patente deverá chegar ao Spring como uma permissão reconhecida pela aplicação. Isso exige mapear a patente para uma role, disponibilizá-la ao cliente OIDC e configurar o Spring Security para usá-la ao proteger a missão.

## Experimento final

Para uma missão que exige a role `jonin`:

1. Entrar como Kakashi e confirmar que ele consegue acessar a missão.
2. Entrar como Sakura. Ela deve conseguir abrir `/me`, mas receber `403 Forbidden` ao tentar a mesma missão.
3. Promover Sakura de `chunin` para `jonin` na Academia, iniciar uma nova sessão e confirmar que ela passou a ter acesso.

O segundo teste demonstra a diferença entre os dois conceitos centrais da PoC: o login identifica Sakura corretamente, e a regra de autorização decide se sua patente permite aquela missão.

## Documentação oficial

- [Keycloak — primeiros passos com Docker](https://www.keycloak.org/getting-started/getting-started-docker)
- [Keycloak — administração de realms, clientes e roles](https://www.keycloak.org/docs/latest/server_admin/)
- [Keycloak — desenvolvimento de User Storage Providers](https://www.keycloak.org/docs/latest/server_development/index.html#_user-storage-spi)
- [Spring Boot — integração com OAuth2 e OpenID Connect](https://docs.spring.io/spring-boot/reference/security/oauth2.html)
- [Red Hat build of Keycloak 26.6 — User Storage SPI](https://docs.redhat.com/en/documentation/red_hat_build_of_keycloak/26.6/html/server_developer_guide/user-storage-spi)