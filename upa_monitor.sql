/* =====================================================================
   UPA MONITOR - PORTO VELHO | SQL Server (T-SQL) | versao 3
   Base: prints do UPA Monitor (6 UPAs, 15 setores, 5 classificacoes,
   2 tempos medios por UPA).
   NOVO: FILA, PACIENTE, TEMPO_MEDIO, MOVIMENTACAO_FILA.
   ATENCAO: o sistema NAO exibe pacientes nem movimentacoes. PACIENTE e
   MOVIMENTACAO_FILA sao a estrutura necessaria para medir o tempo de mudanca
   de fila; os dados carregados nelas sao 100% FICTICIOS (codigo 'TESTE-nnn').
   Dados de UPA/SETOR/MEDICAO_*/TEMPO_MEDIO: valores reais lidos dos prints.
   AJUSTE @data/@hora para o momento da captura.
   ===================================================================== */
CREATE TABLE UPA (
    id_upa INT IDENTITY(1,1) PRIMARY KEY,
    nome   NVARCHAR(100) NOT NULL UNIQUE
);
CREATE TABLE SETOR (                       -- 15 indicadores "Pacientes por setor"
    id_setor INT IDENTITY(1,1) PRIMARY KEY,
    codigo   VARCHAR(40)  NOT NULL UNIQUE,
    nome     NVARCHAR(60) NOT NULL UNIQUE,
    natureza VARCHAR(10)  NOT NULL CHECK (natureza IN ('FILA','PRODUCAO'))
);
CREATE TABLE CLASSIFICACAO_RISCO (
    id_classificacao INT PRIMARY KEY,
    nome       NVARCHAR(20) NOT NULL UNIQUE,
    cor        VARCHAR(10)  NOT NULL UNIQUE,
    prioridade INT NOT NULL UNIQUE
);
CREATE TABLE FILA (                        -- etapas de espera/atendimento do fluxo
    id_fila INT PRIMARY KEY,
    codigo  VARCHAR(30)  NOT NULL UNIQUE,
    nome    NVARCHAR(40) NOT NULL UNIQUE,
    ordem   INT NOT NULL UNIQUE            -- sequencia no fluxo
);
CREATE TABLE MONITORAMENTO (               -- "foto" de uma UPA
    id_monitoramento INT IDENTITY(1,1) PRIMARY KEY,
    id_upa      INT NOT NULL REFERENCES UPA(id_upa),
    data_coleta DATE NOT NULL,
    hora_coleta TIME(0) NOT NULL,
    CONSTRAINT UK_MONIT UNIQUE (id_upa, data_coleta, hora_coleta)
);
CREATE TABLE TEMPO_MEDIO (                 -- tempo medio de espera por fila, na coleta
    id_monitoramento INT NOT NULL REFERENCES MONITORAMENTO(id_monitoramento),
    id_fila          INT NOT NULL REFERENCES FILA(id_fila),
    tempo_medio_seg  INT NOT NULL CHECK (tempo_medio_seg >= 0),
    PRIMARY KEY (id_monitoramento, id_fila)
);
CREATE TABLE MEDICAO_RISCO (               -- fila aguardando consultorio por classificacao
    id_monitoramento INT NOT NULL REFERENCES MONITORAMENTO(id_monitoramento),
    id_classificacao INT NOT NULL REFERENCES CLASSIFICACAO_RISCO(id_classificacao),
    qtd_aguardando   INT NOT NULL CHECK (qtd_aguardando >= 0),
    PRIMARY KEY (id_monitoramento, id_classificacao)
);
CREATE TABLE MEDICAO_SETOR (               -- "Pacientes por setor"
    id_monitoramento INT NOT NULL REFERENCES MONITORAMENTO(id_monitoramento),
    id_setor         INT NOT NULL REFERENCES SETOR(id_setor),
    qtd_pacientes    INT NOT NULL CHECK (qtd_pacientes >= 0),
    PRIMARY KEY (id_monitoramento, id_setor)
);
CREATE TABLE PACIENTE (                    -- uma linha por passagem pela UPA, PSEUDONIMIZADA (LGPD)
    id_paciente      INT IDENTITY(1,1) PRIMARY KEY,
    id_upa           INT NOT NULL REFERENCES UPA(id_upa),
    id_classificacao INT NULL REFERENCES CLASSIFICACAO_RISCO(id_classificacao), -- NULL ate a triagem
    codigo_ficha     VARCHAR(20) NOT NULL,   -- senha/ficha; sem nome nem CPF
    data_chegada     DATE NOT NULL,
    hora_chegada     TIME(0) NOT NULL,
    CONSTRAINT UK_PACIENTE UNIQUE (id_upa, codigo_ficha, data_chegada)
);
CREATE TABLE MOVIMENTACAO_FILA (           -- cada mudanca de fila de um paciente
    id_movimentacao   INT IDENTITY(1,1) PRIMARY KEY,
    id_paciente       INT NOT NULL REFERENCES PACIENTE(id_paciente),
    id_fila_origem    INT NULL REFERENCES FILA(id_fila),     -- NULL = chegada
    id_fila_destino   INT NOT NULL REFERENCES FILA(id_fila),
    data_movimentacao DATE NOT NULL,
    hora_movimentacao TIME(0) NOT NULL,
    CONSTRAINT CK_MOV CHECK (id_fila_origem IS NULL OR id_fila_origem <> id_fila_destino)
);
GO
-- ---------------- CARGA ----------------
DECLARE @data DATE = '2026-10-28', @hora TIME(0) = '12:00:00';   -- << AJUSTAR
INSERT INTO CLASSIFICACAO_RISCO VALUES
 (1,N'EMERGÊNCIA','Vermelho',1),(2,N'MUITO URGENTE','Laranja',2),(3,N'URGENTE','Amarelo',3),
 (4,N'POUCO URGENTE','Verde',4),(5,N'NÃO URGENTE','Azul',5);
INSERT INTO FILA VALUES (1,'AGUARDANDO_TRIAGEM',N'AGUARDANDO TRIAGEM',1),(2,'AGUARDANDO_CONSULTORIO',N'AGUARDANDO CONSULTÓRIO',2),(3,'EM_CONSULTORIO',N'EM CONSULTÓRIO',3);

INSERT INTO SETOR (codigo,nome,natureza) VALUES ('AGUARDANDO_TRIAGEM',N'AGUARDANDO TRIAGEM','FILA');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('PACIENTES_TRIADOS',N'PACIENTES TRIADOS','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('ATENDIDOS_CONSULTORIO',N'ATENDIDOS CONSULTÓRIO','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('SUTURA',N'SUTURA','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('SALA_VERMELHA',N'SALA VERMELHA','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('OBSERVACAO_MASCULINA',N'OBSERVAÇÃO MASCULINA','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('OBSERVACAO_FEMININA',N'OBSERVAÇÃO FEMININA','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('OBSERVACAO_INFANTIL',N'OBSERVAÇÃO INFANTIL','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('MEDICACAO_ADMINISTRADA',N'MEDICAÇÃO ADMINISTRADA','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('EXAMES_LABORATORIO',N'EXAMES LABORATÓRIO','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('EXAMES_RADIOLOGIA',N'EXAMES RADIOLOGIA','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('ODONTOLOGIA',N'ODONTOLOGIA','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('ATENDIMENTO_PEDIATRICO',N'ATENDIMENTO PEDIÁTRICO','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('ASSISTENCIA_SOCIAL',N'ASSISTÊNCIA SOCIAL','PRODUCAO');
INSERT INTO SETOR (codigo,nome,natureza) VALUES ('TRANSFERENCIAS',N'TRANSFERÊNCIAS','PRODUCAO');
INSERT INTO UPA (nome) VALUES (N'UPA LESTE');
INSERT INTO UPA (nome) VALUES (N'UPA LESTE EXTENSÃO - ODONTOLOGIA');
INSERT INTO UPA (nome) VALUES (N'UPA SUL');
INSERT INTO UPA (nome) VALUES (N'ANA ADELAIDE');
INSERT INTO UPA (nome) VALUES (N'UPA JOSÉ ADELINO DA SILVA');
INSERT INTO UPA (nome) VALUES (N'JACI PARANÁ');
INSERT INTO MONITORAMENTO (id_upa,data_coleta,hora_coleta) VALUES (1,@data,@hora);
INSERT INTO MONITORAMENTO (id_upa,data_coleta,hora_coleta) VALUES (2,@data,@hora);
INSERT INTO MONITORAMENTO (id_upa,data_coleta,hora_coleta) VALUES (3,@data,@hora);
INSERT INTO MONITORAMENTO (id_upa,data_coleta,hora_coleta) VALUES (4,@data,@hora);
INSERT INTO MONITORAMENTO (id_upa,data_coleta,hora_coleta) VALUES (5,@data,@hora);
INSERT INTO MONITORAMENTO (id_upa,data_coleta,hora_coleta) VALUES (6,@data,@hora);
-- Tempos medios dos prints (segundos): fila 1 = 'Classificacao', fila 2 = 'Consultorio'. Extensao nao exibe.
INSERT INTO TEMPO_MEDIO VALUES (1,1,519);
INSERT INTO TEMPO_MEDIO VALUES (1,2,1713);
INSERT INTO TEMPO_MEDIO VALUES (3,1,422);
INSERT INTO TEMPO_MEDIO VALUES (3,2,4184);
INSERT INTO TEMPO_MEDIO VALUES (4,1,1209);
INSERT INTO TEMPO_MEDIO VALUES (4,2,3033);
INSERT INTO TEMPO_MEDIO VALUES (5,1,421);
INSERT INTO TEMPO_MEDIO VALUES (5,2,1133);
INSERT INTO TEMPO_MEDIO VALUES (6,1,575);
INSERT INTO TEMPO_MEDIO VALUES (6,2,529);
INSERT INTO MEDICAO_RISCO VALUES (1,1,0);
INSERT INTO MEDICAO_RISCO VALUES (1,2,0);
INSERT INTO MEDICAO_RISCO VALUES (1,3,1);
INSERT INTO MEDICAO_RISCO VALUES (1,4,6);
INSERT INTO MEDICAO_RISCO VALUES (1,5,0);
INSERT INTO MEDICAO_SETOR VALUES (1,1,1);
INSERT INTO MEDICAO_SETOR VALUES (1,2,266);
INSERT INTO MEDICAO_SETOR VALUES (1,3,224);
INSERT INTO MEDICAO_SETOR VALUES (1,4,33);
INSERT INTO MEDICAO_SETOR VALUES (1,5,4);
INSERT INTO MEDICAO_SETOR VALUES (1,6,8);
INSERT INTO MEDICAO_SETOR VALUES (1,7,2);
INSERT INTO MEDICAO_SETOR VALUES (1,8,0);
INSERT INTO MEDICAO_SETOR VALUES (1,9,403);
INSERT INTO MEDICAO_SETOR VALUES (1,10,137);
INSERT INTO MEDICAO_SETOR VALUES (1,11,76);
INSERT INTO MEDICAO_SETOR VALUES (1,12,1);
INSERT INTO MEDICAO_SETOR VALUES (1,13,49);
INSERT INTO MEDICAO_SETOR VALUES (1,14,5);
INSERT INTO MEDICAO_RISCO VALUES (2,1,0);
INSERT INTO MEDICAO_RISCO VALUES (2,2,0);
INSERT INTO MEDICAO_RISCO VALUES (2,3,0);
INSERT INTO MEDICAO_RISCO VALUES (2,4,0);
INSERT INTO MEDICAO_RISCO VALUES (2,5,0);
INSERT INTO MEDICAO_SETOR VALUES (2,1,0);
INSERT INTO MEDICAO_SETOR VALUES (2,2,0);
INSERT INTO MEDICAO_SETOR VALUES (2,3,0);
INSERT INTO MEDICAO_SETOR VALUES (2,4,0);
INSERT INTO MEDICAO_SETOR VALUES (2,5,0);
INSERT INTO MEDICAO_SETOR VALUES (2,6,0);
INSERT INTO MEDICAO_SETOR VALUES (2,7,0);
INSERT INTO MEDICAO_SETOR VALUES (2,8,0);
INSERT INTO MEDICAO_SETOR VALUES (2,9,0);
INSERT INTO MEDICAO_SETOR VALUES (2,10,0);
INSERT INTO MEDICAO_SETOR VALUES (2,11,0);
INSERT INTO MEDICAO_SETOR VALUES (2,12,8);
INSERT INTO MEDICAO_SETOR VALUES (2,13,0);
INSERT INTO MEDICAO_SETOR VALUES (2,14,0);
INSERT INTO MEDICAO_SETOR VALUES (2,15,0);
INSERT INTO MEDICAO_RISCO VALUES (3,1,0);
INSERT INTO MEDICAO_RISCO VALUES (3,2,0);
INSERT INTO MEDICAO_RISCO VALUES (3,3,3);
INSERT INTO MEDICAO_RISCO VALUES (3,4,22);
INSERT INTO MEDICAO_RISCO VALUES (3,5,0);
INSERT INTO MEDICAO_SETOR VALUES (3,1,1);
INSERT INTO MEDICAO_SETOR VALUES (3,2,285);
INSERT INTO MEDICAO_SETOR VALUES (3,3,213);
INSERT INTO MEDICAO_SETOR VALUES (3,4,38);
INSERT INTO MEDICAO_SETOR VALUES (3,5,4);
INSERT INTO MEDICAO_SETOR VALUES (3,6,14);
INSERT INTO MEDICAO_SETOR VALUES (3,7,17);
INSERT INTO MEDICAO_SETOR VALUES (3,8,5);
INSERT INTO MEDICAO_SETOR VALUES (3,9,332);
INSERT INTO MEDICAO_SETOR VALUES (3,10,303);
INSERT INTO MEDICAO_SETOR VALUES (3,11,98);
INSERT INTO MEDICAO_SETOR VALUES (3,12,15);
INSERT INTO MEDICAO_SETOR VALUES (3,13,43);
INSERT INTO MEDICAO_SETOR VALUES (3,14,0);
INSERT INTO MEDICAO_SETOR VALUES (3,15,20);
INSERT INTO MEDICAO_RISCO VALUES (4,1,0);
INSERT INTO MEDICAO_RISCO VALUES (4,2,0);
INSERT INTO MEDICAO_RISCO VALUES (4,3,3);
INSERT INTO MEDICAO_RISCO VALUES (4,4,8);
INSERT INTO MEDICAO_RISCO VALUES (4,5,2);
INSERT INTO MEDICAO_SETOR VALUES (4,1,6);
INSERT INTO MEDICAO_SETOR VALUES (4,2,222);
INSERT INTO MEDICAO_SETOR VALUES (4,3,196);
INSERT INTO MEDICAO_SETOR VALUES (4,4,15);
INSERT INTO MEDICAO_SETOR VALUES (4,5,2);
INSERT INTO MEDICAO_SETOR VALUES (4,6,34);
INSERT INTO MEDICAO_SETOR VALUES (4,7,31);
INSERT INTO MEDICAO_SETOR VALUES (4,8,5);
INSERT INTO MEDICAO_SETOR VALUES (4,9,371);
INSERT INTO MEDICAO_SETOR VALUES (4,10,209);
INSERT INTO MEDICAO_SETOR VALUES (4,11,66);
INSERT INTO MEDICAO_SETOR VALUES (4,12,0);
INSERT INTO MEDICAO_SETOR VALUES (4,13,50);
INSERT INTO MEDICAO_SETOR VALUES (4,14,0);
INSERT INTO MEDICAO_SETOR VALUES (4,15,1);
INSERT INTO MEDICAO_RISCO VALUES (5,1,0);
INSERT INTO MEDICAO_RISCO VALUES (5,2,0);
INSERT INTO MEDICAO_RISCO VALUES (5,3,0);
INSERT INTO MEDICAO_RISCO VALUES (5,4,4);
INSERT INTO MEDICAO_RISCO VALUES (5,5,0);
INSERT INTO MEDICAO_SETOR VALUES (5,1,0);
INSERT INTO MEDICAO_SETOR VALUES (5,2,196);
INSERT INTO MEDICAO_SETOR VALUES (5,3,181);
INSERT INTO MEDICAO_SETOR VALUES (5,4,1);
INSERT INTO MEDICAO_SETOR VALUES (5,5,7);
INSERT INTO MEDICAO_SETOR VALUES (5,6,0);
INSERT INTO MEDICAO_SETOR VALUES (5,7,0);
INSERT INTO MEDICAO_SETOR VALUES (5,8,0);
INSERT INTO MEDICAO_SETOR VALUES (5,9,314);
INSERT INTO MEDICAO_SETOR VALUES (5,10,92);
INSERT INTO MEDICAO_SETOR VALUES (5,11,44);
INSERT INTO MEDICAO_SETOR VALUES (5,12,0);
INSERT INTO MEDICAO_SETOR VALUES (5,13,40);
INSERT INTO MEDICAO_SETOR VALUES (5,14,0);
INSERT INTO MEDICAO_SETOR VALUES (5,15,1);
INSERT INTO MEDICAO_RISCO VALUES (6,1,0);
INSERT INTO MEDICAO_RISCO VALUES (6,2,0);
INSERT INTO MEDICAO_RISCO VALUES (6,3,0);
INSERT INTO MEDICAO_RISCO VALUES (6,4,0);
INSERT INTO MEDICAO_RISCO VALUES (6,5,0);
INSERT INTO MEDICAO_SETOR VALUES (6,1,0);
INSERT INTO MEDICAO_SETOR VALUES (6,2,47);
INSERT INTO MEDICAO_SETOR VALUES (6,3,41);
INSERT INTO MEDICAO_SETOR VALUES (6,4,1);
INSERT INTO MEDICAO_SETOR VALUES (6,5,0);
INSERT INTO MEDICAO_SETOR VALUES (6,6,4);
INSERT INTO MEDICAO_SETOR VALUES (6,7,7);
INSERT INTO MEDICAO_SETOR VALUES (6,8,1);
INSERT INTO MEDICAO_SETOR VALUES (6,9,65);
INSERT INTO MEDICAO_SETOR VALUES (6,10,21);
INSERT INTO MEDICAO_SETOR VALUES (6,11,11);
INSERT INTO MEDICAO_SETOR VALUES (6,12,0);
INSERT INTO MEDICAO_SETOR VALUES (6,13,11);
INSERT INTO MEDICAO_SETOR VALUES (6,14,0);
INSERT INTO MEDICAO_SETOR VALUES (6,15,1);
-- Obs.: 'UPA LESTE / TRANSFERENCIAS' estava cortada no print e nao foi inserida.

-- >>> DADOS FICTICIOS (teste do fluxo entre filas) <<<
INSERT INTO PACIENTE (id_upa,id_classificacao,codigo_ficha,data_chegada,hora_chegada) VALUES (3,4,'TESTE-001',@data,'08:00:00');
INSERT INTO PACIENTE (id_upa,id_classificacao,codigo_ficha,data_chegada,hora_chegada) VALUES (3,3,'TESTE-002',@data,'08:05:00');
INSERT INTO PACIENTE (id_upa,id_classificacao,codigo_ficha,data_chegada,hora_chegada) VALUES (3,4,'TESTE-003',@data,'08:10:00');
INSERT INTO PACIENTE (id_upa,id_classificacao,codigo_ficha,data_chegada,hora_chegada) VALUES (3,5,'TESTE-004',@data,'08:20:00');
INSERT INTO PACIENTE (id_upa,id_classificacao,codigo_ficha,data_chegada,hora_chegada) VALUES (1,4,'TESTE-005',@data,'08:30:00');
INSERT INTO PACIENTE (id_upa,id_classificacao,codigo_ficha,data_chegada,hora_chegada) VALUES (1,3,'TESTE-006',@data,'08:40:00');
INSERT INTO PACIENTE (id_upa,id_classificacao,codigo_ficha,data_chegada,hora_chegada) VALUES (1,NULL,'TESTE-007',@data,'09:00:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (1,NULL,1,@data,'08:00:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (1,1,2,@data,'08:06:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (1,2,3,@data,'08:56:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (2,NULL,1,@data,'08:05:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (2,1,2,@data,'08:12:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (2,2,3,@data,'08:32:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (3,NULL,1,@data,'08:10:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (3,1,2,@data,'08:15:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (3,2,3,@data,'09:30:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (4,NULL,1,@data,'08:20:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (4,1,2,@data,'08:28:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (5,NULL,1,@data,'08:30:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (5,1,2,@data,'08:39:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (5,2,3,@data,'09:44:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (6,NULL,1,@data,'08:40:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (6,1,2,@data,'08:45:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (6,2,3,@data,'09:00:00');
INSERT INTO MOVIMENTACAO_FILA VALUES (7,NULL,1,@data,'09:00:00');
GO
/* ====================== PROCEDURE 1 ====================== */
CREATE OR ALTER PROCEDURE dbo.sp_quadro_de_filas
    @id_upa INT = NULL                      -- NULL = todas as UPAs
AS
BEGIN
    SET NOCOUNT ON;

    -- Ultima coleta de CADA UPA (fila e um ESTOQUE: nao pode ser somada entre coletas)
    WITH ultima AS (
        SELECT mo.id_monitoramento, mo.id_upa, mo.data_coleta, mo.hora_coleta,
               tm.tc, tm.tq,
               ROW_NUMBER() OVER (PARTITION BY mo.id_upa
                                  ORDER BY mo.data_coleta DESC, mo.hora_coleta DESC) AS rn
        FROM MONITORAMENTO mo
        OUTER APPLY (                        -- tempos da tabela TEMPO_MEDIO (NULL se a UPA nao exibe)
            SELECT MAX(CASE WHEN f.codigo = 'AGUARDANDO_TRIAGEM'     THEN t.tempo_medio_seg END) AS tc,
                   MAX(CASE WHEN f.codigo = 'AGUARDANDO_CONSULTORIO' THEN t.tempo_medio_seg END) AS tq
            FROM TEMPO_MEDIO t JOIN FILA f ON f.id_fila = t.id_fila
            WHERE t.id_monitoramento = mo.id_monitoramento
        ) tm
        WHERE @id_upa IS NULL OR mo.id_upa = @id_upa
    ),
    risco AS (                               -- fila por cor, uma linha por coleta
        SELECT mr.id_monitoramento,
               SUM(CASE WHEN c.prioridade = 1 THEN mr.qtd_aguardando ELSE 0 END) AS emergencia,
               SUM(CASE WHEN c.prioridade = 2 THEN mr.qtd_aguardando ELSE 0 END) AS muito_urgente,
               SUM(CASE WHEN c.prioridade = 3 THEN mr.qtd_aguardando ELSE 0 END) AS urgente,
               SUM(CASE WHEN c.prioridade = 4 THEN mr.qtd_aguardando ELSE 0 END) AS pouco_urgente,
               SUM(CASE WHEN c.prioridade = 5 THEN mr.qtd_aguardando ELSE 0 END) AS nao_urgente
        FROM MEDICAO_RISCO mr JOIN CLASSIFICACAO_RISCO c ON c.id_classificacao = mr.id_classificacao
        GROUP BY mr.id_monitoramento
    ),
    setor AS (                               -- fila de triagem e PESOS para medias ponderadas
        SELECT ms.id_monitoramento,
               MAX(CASE WHEN s.codigo = 'AGUARDANDO_TRIAGEM'      THEN ms.qtd_pacientes END) AS aguardando_triagem,
               MAX(CASE WHEN s.codigo = 'PACIENTES_TRIADOS'       THEN ms.qtd_pacientes END) AS triados,
               MAX(CASE WHEN s.codigo = 'ATENDIDOS_CONSULTORIO'   THEN ms.qtd_pacientes END) AS atendidos
        FROM MEDICAO_SETOR ms JOIN SETOR s ON s.id_setor = ms.id_setor
        GROUP BY ms.id_monitoramento
    ),
    base AS (
        SELECT u.nome AS upa, ul.data_coleta, ul.hora_coleta, ul.tc, ul.tq,
               ISNULL(st.aguardando_triagem,0) AS aguardando_triagem,
               ISNULL(st.triados,0) AS triados, ISNULL(st.atendidos,0) AS atendidos,
               r.emergencia, r.muito_urgente, r.urgente, r.pouco_urgente, r.nao_urgente
        FROM ultima ul
        JOIN UPA u        ON u.id_upa = ul.id_upa
        JOIN risco r      ON r.id_monitoramento = ul.id_monitoramento
        LEFT JOIN setor st ON st.id_monitoramento = ul.id_monitoramento
        WHERE ul.rn = 1
    )
    -- ROLLUP gera a linha TOTAL GERAL. Tempos do total = media PONDERADA:
    --   classificacao pesa por pacientes triados; consultorio por atendidos.
    -- Pesos so contam UPAs que tem o tempo informado (Extensao nao exibe tempos).
    SELECT CASE WHEN GROUPING(upa) = 1 THEN 'TOTAL GERAL' ELSE upa END AS upa,
           SUM(aguardando_triagem) AS aguardando_triagem,
           SUM(emergencia) AS emergencia, SUM(muito_urgente) AS muito_urgente,
           SUM(urgente) AS urgente, SUM(pouco_urgente) AS pouco_urgente, SUM(nao_urgente) AS nao_urgente,
           SUM(emergencia+muito_urgente+urgente+pouco_urgente+nao_urgente) AS total_aguardando,
           SUM(emergencia+muito_urgente) AS casos_criticos,   -- HIPOTESE: confirmar definicao no sistema
           CAST(100.0*SUM(emergencia+muito_urgente+urgente)
                / NULLIF(SUM(emergencia+muito_urgente+urgente+pouco_urgente+nao_urgente),0) AS DECIMAL(5,1)) AS pct_urgente_ou_mais,
           CONVERT(CHAR(8), DATEADD(SECOND, CAST(ROUND(SUM(1.0*tc*triados)
                / NULLIF(SUM(CASE WHEN tc IS NOT NULL THEN triados END),0),0) AS INT), 0), 108) AS tempo_medio_classificacao,
           CONVERT(CHAR(8), DATEADD(SECOND, CAST(ROUND(SUM(1.0*tq*atendidos)
                / NULLIF(SUM(CASE WHEN tq IS NOT NULL THEN atendidos END),0),0) AS INT), 0), 108) AS tempo_medio_consultorio
    FROM base
    GROUP BY ROLLUP (upa)
    ORDER BY GROUPING(upa), upa;
END;
GO
/* ====================== PROCEDURE 2 ====================== */
CREATE OR ALTER PROCEDURE dbo.sp_atlas_e_cubos
    @data_inicio DATE = NULL,
    @data_fim    DATE = NULL,
    @id_upa      INT  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Contadores "por setor" sao ACUMULADOS no dia (hipotese a confirmar):
    -- por UPA/setor/dia usa-se o MAIOR valor; so entao soma-se entre dias.
    SELECT mo.id_upa, mo.data_coleta, ms.id_setor, MAX(ms.qtd_pacientes) AS qtd
    INTO #diario
    FROM MONITORAMENTO mo JOIN MEDICAO_SETOR ms ON ms.id_monitoramento = mo.id_monitoramento
    WHERE (@data_inicio IS NULL OR mo.data_coleta >= @data_inicio)
      AND (@data_fim    IS NULL OR mo.data_coleta <= @data_fim)
      AND (@id_upa      IS NULL OR mo.id_upa = @id_upa)
    GROUP BY mo.id_upa, mo.data_coleta, ms.id_setor;

    -- Resultado 1 (CUBO UPA x SETOR): total por UPA/setor e total do setor em TODAS as UPAs.
    -- NAO ha total "todos os setores": triados, atendidos e procedimentos
    -- se sobrepoem (o mesmo paciente aparece em varios) e AGUARDANDO_TRIAGEM e estoque.
    SELECT CASE WHEN GROUPING(u.nome) = 1 THEN N'TODAS AS UPAs' ELSE u.nome END AS upa,
           s.nome AS setor,
           COUNT(DISTINCT d.data_coleta) AS dias_com_coleta,
           SUM(d.qtd) AS total_pacientes
    FROM #diario d
    JOIN UPA u   ON u.id_upa = d.id_upa
    JOIN SETOR s ON s.id_setor = d.id_setor
    WHERE s.natureza = 'PRODUCAO'
    GROUP BY GROUPING SETS ((u.nome, s.nome), (s.nome))
    ORDER BY s.nome, GROUPING(u.nome), u.nome;

    -- Resultado 2: desempenho por UPA (+ TOTAL GERAL)
    WITH dia AS (
        SELECT d.id_upa, d.data_coleta,
               MAX(CASE WHEN s.codigo='PACIENTES_TRIADOS'     THEN d.qtd END) AS triados,
               MAX(CASE WHEN s.codigo='ATENDIDOS_CONSULTORIO' THEN d.qtd END) AS atendidos
        FROM #diario d JOIN SETOR s ON s.id_setor = d.id_setor
        GROUP BY d.id_upa, d.data_coleta
    ),
    tempos AS (                              -- tempo do dia = ultima coleta do dia
        SELECT mo.id_upa, mo.data_coleta, tm.tc, tm.tq,
               ROW_NUMBER() OVER (PARTITION BY mo.id_upa, mo.data_coleta ORDER BY mo.hora_coleta DESC) AS rn
        FROM MONITORAMENTO mo
        OUTER APPLY (
            SELECT MAX(CASE WHEN f.codigo = 'AGUARDANDO_TRIAGEM'     THEN t.tempo_medio_seg END) AS tc,
                   MAX(CASE WHEN f.codigo = 'AGUARDANDO_CONSULTORIO' THEN t.tempo_medio_seg END) AS tq
            FROM TEMPO_MEDIO t JOIN FILA f ON f.id_fila = t.id_fila
            WHERE t.id_monitoramento = mo.id_monitoramento
        ) tm
        WHERE (@data_inicio IS NULL OR mo.data_coleta >= @data_inicio)
          AND (@data_fim    IS NULL OR mo.data_coleta <= @data_fim)
          AND (@id_upa      IS NULL OR mo.id_upa = @id_upa)
    )
    SELECT CASE WHEN GROUPING(u.nome) = 1 THEN N'TOTAL GERAL' ELSE u.nome END AS upa,
           SUM(di.triados)   AS pacientes_triados,
           SUM(di.atendidos) AS atendidos_consultorio,
           CAST(100.0*SUM(di.atendidos)/NULLIF(SUM(di.triados),0) AS DECIMAL(5,1)) AS pct_atendidos_sobre_triados,
           CONVERT(CHAR(8), DATEADD(SECOND, CAST(ROUND(SUM(1.0*t.tc*di.triados)
                / NULLIF(SUM(CASE WHEN t.tc IS NOT NULL THEN di.triados END),0),0) AS INT), 0), 108) AS tempo_medio_classificacao,
           CONVERT(CHAR(8), DATEADD(SECOND, CAST(ROUND(SUM(1.0*t.tq*di.atendidos)
                / NULLIF(SUM(CASE WHEN t.tq IS NOT NULL THEN di.atendidos END),0),0) AS INT), 0), 108) AS tempo_medio_consultorio
    FROM dia di
    JOIN tempos t ON t.id_upa = di.id_upa AND t.data_coleta = di.data_coleta AND t.rn = 1
    JOIN UPA u    ON u.id_upa = di.id_upa
    GROUP BY ROLLUP (u.nome)
    ORDER BY GROUPING(u.nome), u.nome;

    DROP TABLE #diario;
END;
GO
/* ====================== PROCEDURE 3 (NOVA) ====================== */
-- Tempo de mudanca de uma fila para outra, calculado a partir de MOVIMENTACAO_FILA.
-- Tempo na fila de origem = momento da mudanca - momento da movimentacao anterior do MESMO paciente (LAG).
-- Pacientes que ainda estao na fila (sem a proxima movimentacao) nao entram na media.
CREATE OR ALTER PROCEDURE dbo.sp_tempo_transicao_filas
    @data_inicio DATE = NULL,
    @data_fim    DATE = NULL,
    @id_upa      INT  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH mov AS (
        SELECT mf.id_movimentacao, mf.id_paciente, p.id_upa, p.id_classificacao,
               mf.id_fila_origem, mf.id_fila_destino,
               DATEADD(SECOND, DATEDIFF(SECOND, '00:00:00', mf.hora_movimentacao),
                       CAST(mf.data_movimentacao AS DATETIME2(0))) AS dt_mov
        FROM MOVIMENTACAO_FILA mf
        JOIN PACIENTE p ON p.id_paciente = mf.id_paciente
        WHERE (@data_inicio IS NULL OR p.data_chegada >= @data_inicio)
          AND (@data_fim    IS NULL OR p.data_chegada <= @data_fim)
          AND (@id_upa      IS NULL OR p.id_upa = @id_upa)
    ),
    par AS (
        SELECT *, LAG(dt_mov) OVER (PARTITION BY id_paciente ORDER BY dt_mov, id_movimentacao) AS dt_anterior
        FROM mov
    )
    SELECT par.id_upa, par.id_classificacao, fo.ordem AS ordem_origem,
           fo.nome + N' -> ' + fd.nome AS transicao,
           DATEDIFF(SECOND, par.dt_anterior, par.dt_mov) AS tempo_seg
    INTO #t
    FROM par
    JOIN FILA fo ON fo.id_fila = par.id_fila_origem
    JOIN FILA fd ON fd.id_fila = par.id_fila_destino
    WHERE par.id_fila_origem IS NOT NULL AND par.dt_anterior IS NOT NULL;   -- ignora a chegada

    -- Resultado 1: por UPA e total, para cada transicao
    SELECT CASE WHEN GROUPING(u.nome) = 1 THEN N'TODAS AS UPAs' ELSE u.nome END AS upa,
           t.transicao,
           COUNT(*) AS pacientes,
           CONVERT(CHAR(8), DATEADD(SECOND, CAST(ROUND(AVG(1.0*t.tempo_seg),0) AS INT), 0), 108) AS tempo_medio,
           CONVERT(CHAR(8), DATEADD(SECOND, MIN(t.tempo_seg), 0), 108) AS tempo_minimo,
           CONVERT(CHAR(8), DATEADD(SECOND, MAX(t.tempo_seg), 0), 108) AS tempo_maximo
    FROM #t t JOIN UPA u ON u.id_upa = t.id_upa
    GROUP BY GROUPING SETS ((t.ordem_origem, t.transicao, u.nome), (t.ordem_origem, t.transicao))
    ORDER BY t.ordem_origem, GROUPING(u.nome), u.nome;

    -- Resultado 2: por classificacao de risco (so quem ja foi classificado)
    SELECT t.transicao, c.nome AS classificacao,
           COUNT(*) AS pacientes,
           CONVERT(CHAR(8), DATEADD(SECOND, CAST(ROUND(AVG(1.0*t.tempo_seg),0) AS INT), 0), 108) AS tempo_medio
    FROM #t t JOIN CLASSIFICACAO_RISCO c ON c.id_classificacao = t.id_classificacao
    GROUP BY t.ordem_origem, t.transicao, c.prioridade, c.nome
    ORDER BY t.ordem_origem, c.prioridade;

    DROP TABLE #t;
END;
GO
EXEC dbo.sp_quadro_de_filas;
EXEC dbo.sp_atlas_e_cubos;
EXEC dbo.sp_tempo_transicao_filas;
