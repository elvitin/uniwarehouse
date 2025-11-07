-- =====================================================================
-- Script para Criação do Data Warehouse (DW) - Modelo Dimensional
-- Objetivo: Análise de Evasão e Desempenho Acadêmico
-- =====================================================================

-- -----------------------------------------------------
-- Tabela de Dimensão: Dim_Tempo
-- Descrição: Fornece granularidade temporal para as análises (anual, semestral, mensal).
-- -----------------------------------------------------
CREATE TABLE Dim_Tempo (
    id_tempo SERIAL PRIMARY KEY,
    data DATE NOT NULL,
    ano INT NOT NULL,
    semestre INT NOT NULL,
    trimestre INT NOT NULL,
    mes INT NOT NULL,
    nome_mes VARCHAR(20) NOT NULL,
    dia_semana INT NOT NULL,
    nome_dia_semana VARCHAR(20) NOT NULL,
    ano_semestre VARCHAR(7) -- Ex: '2023.1'
);

-- -----------------------------------------------------
-- Tabela de Dimensão: Dim_Aluno
-- Descrição: Armazena os atributos dos alunos, incluindo dados demográficos e socioeconômicos.
-- -----------------------------------------------------
CREATE TABLE Dim_Aluno (
    id_aluno SERIAL PRIMARY KEY,
    nk_aluno INT NOT NULL, -- Chave natural (ID da tabela original Alunos)
    nome_completo VARCHAR(255) NOT NULL,
    sexo VARCHAR(255),
    faixa_etaria VARCHAR(20), -- Ex: '18-24', '25-30'
    faixa_renda VARCHAR(50), -- Ex: 'Até 2 salários', 'De 2 a 5 salários'
    moradia VARCHAR(45),
    possui_bolsa BOOLEAN,
    percentual_bolsa INT,
    tipo_escolar_origem VARCHAR(45),
    status_evasao BOOLEAN DEFAULT FALSE, -- TRUE se o aluno evadiu
    data_desligamento DATE
);

-- -----------------------------------------------------
-- Tabela de Dimensão: Dim_Curso
-- Descrição: Armazena os atributos dos cursos oferecidos pela instituição.
-- -----------------------------------------------------
CREATE TABLE Dim_Curso (
    id_curso SERIAL PRIMARY KEY,
    nk_curso INT NOT NULL, -- Chave natural (ID da tabela original Cursos)
    nome VARCHAR(45) NOT NULL,
    nivel VARCHAR(255),
    forma_oferta forma_oferta_enum,
    turno turno_enum,
    duracao_semestres INT
);

-- -----------------------------------------------------
-- Tabela de Dimensão: Dim_Disciplina
-- Descrição: Armazena os atributos das disciplinas.
-- -----------------------------------------------------
CREATE TABLE Dim_Disciplina (
    id_disciplina SERIAL PRIMARY KEY,
    nk_disciplina INT NOT NULL, -- Chave natural (ID da tabela original Disciplinas)
    nome VARCHAR(45) NOT NULL,
    carga_horaria_total INT
);

-- -----------------------------------------------------
-- Tabela de Dimensão: Dim_Professor
-- Descrição: Armazena os atributos dos professores.
-- -----------------------------------------------------
CREATE TABLE Dim_Professor (
    id_professor SERIAL PRIMARY KEY,
    nk_professor INT NOT NULL, -- Chave natural (ID da tabela original Professores)
    nome VARCHAR(255) NOT NULL,
    titulacao VARCHAR(50),
    area_atuacao VARCHAR(255)
);

-- -----------------------------------------------------
-- Tabela Fato: Fato_Academico
-- Descrição: Tabela principal que registra o desempenho do aluno em cada disciplina por semestre.
-- Granularidade: Um registro por aluno, por disciplina, por semestre.
-- -----------------------------------------------------
CREATE TABLE Fato_Academico (
    id_aluno INT,
    id_disciplina INT,
    id_curso INT, -- Adicionado para análise de desempenho por curso
    id_professor INT,
    id_tempo_semestre INT, -- Chave para Dim_Tempo, representando o semestre letivo
    semestre_label VARCHAR(45), -- Ex: '2023.1'
    nota_1 NUMERIC(3, 1),
    nota_2 NUMERIC(3, 1),
    media_final NUMERIC(3, 1),
    faltas INT,
    status_aprovacao VARCHAR(20), -- 'Aprovado', 'Reprovado por Nota', 'Reprovado por Falta'
    
    PRIMARY KEY (id_aluno, id_disciplina, id_tempo_semestre),
    FOREIGN KEY (id_aluno) REFERENCES Dim_Aluno(id_aluno),
    FOREIGN KEY (id_disciplina) REFERENCES Dim_Disciplina(id_disciplina),
    FOREIGN KEY (id_curso) REFERENCES Dim_Curso(id_curso),
    FOREIGN KEY (id_professor) REFERENCES Dim_Professor(id_professor),
    FOREIGN KEY (id_tempo_semestre) REFERENCES Dim_Tempo(id_tempo)
);

-- -----------------------------------------------------
-- Tabela Fato: Fato_Financeiro
-- Descrição: Registra os eventos financeiros (faturas) dos alunos.
-- Granularidade: Um registro por fatura.
-- -----------------------------------------------------
CREATE TABLE Fato_Financeiro (
    id_fatura SERIAL PRIMARY KEY,
    nk_fatura INT NOT NULL, -- Chave natural (ID da tabela original Fatura)
    id_aluno INT,
    id_tempo_emissao INT,
    id_tempo_vencimento INT,
    valor_total NUMERIC(10, 2),
    desconto_aplicado NUMERIC(10, 2),
    valor_final NUMERIC(10, 2), -- valor_total - desconto_aplicado
    status_fatura status_fatura_enum,
    dias_atraso INT, -- Calculado no ETL
    
    FOREIGN KEY (id_aluno) REFERENCES Dim_Aluno(id_aluno),
    FOREIGN KEY (id_tempo_emissao) REFERENCES Dim_Tempo(id_tempo),
    FOREIGN KEY (id_tempo_vencimento) REFERENCES Dim_Tempo(id_tempo)
);
