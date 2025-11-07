-- Criação dos tipos ENUM
CREATE TYPE forma_oferta_enum AS ENUM('Presencial', 'EAD');
CREATE TYPE turno_enum AS ENUM('Manhã', 'Tarde', 'Noite');
CREATE TYPE status_fatura_enum AS ENUM('Paga', 'Pendente', 'Atrasada');
CREATE TYPE forma_pagamento_enum AS ENUM('Boleto', 'Cartão de Crédito', 'PIX');
CREATE TYPE tipo_pagamento_enum AS ENUM('Matrícula', 'Mensalidade');

-- Criação da tabela Alunos
CREATE TABLE Alunos (
    id SERIAL PRIMARY KEY,
    nome_completo VARCHAR(255) NOT NULL,
    data_nascimento DATE,
    sexo VARCHAR(255),
    endereco VARCHAR(255),
    renda NUMERIC(10, 2),
    motivo_desistencia VARCHAR(255),
    data_desligamento DATE,
    moradia VARCHAR(45),
    bolsa INT,
    tipo_escolar_origem VARCHAR(45)
);

-- Criação da tabela Cursos
CREATE TABLE Cursos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(45) NOT NULL,
    nivel VARCHAR(255),
    forma_oferta forma_oferta_enum,
    duracao INT,
    vagas INT,
    turno turno_enum
);

-- Criação da tabela Professores
CREATE TABLE Professores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    data_desligamento DATE,
    titulacao VARCHAR(50),
    area_atuacao VARCHAR(255),
    regime_trabalho INT,
    salario NUMERIC(10, 2)
);

-- Criação da tabela Disciplinas
CREATE TABLE Disciplinas (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(45) NOT NULL,
    carga_horaria_total INT
);

-- Criação da tabela Disciplina_Requisitos
CREATE TABLE Disciplina_Requisitos (
    disciplina_id INT,
    disciplina_requisito_id INT,
    PRIMARY KEY (disciplina_id, disciplina_requisito_id),
    FOREIGN KEY (disciplina_id) REFERENCES Disciplinas(id),
    FOREIGN KEY (disciplina_requisito_id) REFERENCES Disciplinas(id)
);

-- Criação da tabela Disciplinas_has_Cursos
CREATE TABLE Disciplinas_has_Cursos (
    disciplina_id INT,
    curso_id INT,
    forma_oferta forma_oferta_enum,
    PRIMARY KEY (disciplina_id, curso_id),
    FOREIGN KEY (disciplina_id) REFERENCES Disciplinas(id),
    FOREIGN KEY (curso_id) REFERENCES Cursos(id)
);

-- Criação da tabela Alunos_Disciplina
CREATE TABLE Alunos_Disciplina (
    aluno_id INT,
    disciplina_id INT,
    semestre VARCHAR(45),
    nota_1 NUMERIC(3, 1),
    nota_2 NUMERIC(3, 1),
    media NUMERIC(3, 1),
    faltas INT,
    avaliacao VARCHAR(255),
    professores_id INT,
    PRIMARY KEY (aluno_id, disciplina_id, semestre),
    FOREIGN KEY (aluno_id) REFERENCES Alunos(id),
    FOREIGN KEY (disciplina_id) REFERENCES Disciplinas(id),
    FOREIGN KEY (professores_id) REFERENCES Professores(id)
);

-- Criação da tabela Fatura
CREATE TABLE Fatura (
    id SERIAL PRIMARY KEY,
    aluno_id INT,
    valor_total NUMERIC(10, 2),
    data_emissao TIMESTAMP,
    data_vencimento TIMESTAMP,
    status_fatura status_fatura_enum,
    desconto_aplicado NUMERIC(10, 2),
    FOREIGN KEY (aluno_id) REFERENCES Alunos(id)
);

-- Criação da tabela Pagamentos
CREATE TABLE Pagamentos (
    id SERIAL PRIMARY KEY,
    valor NUMERIC(10, 2),
    data_pagamento TIMESTAMP,
    forma_pagamento forma_pagamento_enum,
    tipo_pagamento tipo_pagamento_enum,
    fatura_id INT,
    FOREIGN KEY (fatura_id) REFERENCES Fatura(id)
);

-- Inserção de dados para BI

-- Populando a tabela Cursos
INSERT INTO Cursos (nome, nivel, forma_oferta, duracao, vagas, turno) VALUES
('Análise e Desenvolvimento de Sistemas', 'Tecnólogo', 'Presencial', 5, 50, 'Noite'),
('Engenharia de Software', 'Bacharelado', 'Presencial', 10, 40, 'Manhã'),
('Ciência de Dados', 'Pós-graduação', 'EAD', 2, 30, 'Noite'),
('Redes de Computadores', 'Tecnólogo', 'Presencial', 5, 50, 'Tarde'),
('Administração', 'Bacharelado', 'EAD', 8, 100, 'Noite'),
('Marketing Digital', 'Tecnólogo', 'EAD', 4, 80, 'Manhã');

-- Populando a tabela Professores
INSERT INTO Professores (nome, titulacao, area_atuacao, regime_trabalho, salario) VALUES
('Dr. Ricardo Gomes', 'Doutorado', 'Banco de Dados', 40, 8000.00),
('Dra. Ana Souza', 'Doutorado', 'Engenharia de Software', 40, 8500.00),
('Msc. Pedro Martins', 'Mestrado', 'Inteligência Artificial', 20, 4500.00),
('Msc. Carla Dias', 'Mestrado', 'Redes', 40, 7500.00),
('Dr. Fernando Lima', 'Doutorado', 'Administração', 40, 8200.00),
('Esp. Julia Campos', 'Especialização', 'Marketing', 20, 4000.00);

-- Populando a tabela Disciplinas
INSERT INTO Disciplinas (nome, carga_horaria_total) VALUES
('Modelagem de Banco de Dados', 80),
('Programação Orientada a Objetos', 80),
('Inteligência Artificial', 80),
('Segurança de Redes', 80),
('Gestão de Projetos', 60),
('SEO e SEM', 40),
('Estrutura de Dados', 80),
('Contabilidade Geral', 60);

-- Populando a tabela Disciplina_Requisitos
INSERT INTO Disciplina_Requisitos (disciplina_id, disciplina_requisito_id) VALUES
(2, 7), -- POO requer Estrutura de Dados
(3, 2), -- IA requer POO
(4, 1); -- Segurança de Redes requer Modelagem de BD

-- Populando a tabela Disciplinas_has_Cursos
INSERT INTO Disciplinas_has_Cursos (disciplina_id, curso_id, forma_oferta) VALUES
(1, 1, 'Presencial'), (1, 2, 'Presencial'),
(2, 1, 'Presencial'), (2, 2, 'Presencial'),
(3, 3, 'EAD'),
(4, 4, 'Presencial'),
(5, 1, 'Presencial'), (5, 2, 'Presencial'), (5, 5, 'EAD'),
(6, 6, 'EAD'),
(7, 1, 'Presencial'), (7, 2, 'Presencial'),
(8, 5, 'EAD');

-- Populando a tabela Alunos
INSERT INTO Alunos (nome_completo, data_nascimento, sexo, endereco, renda, moradia, bolsa, tipo_escolar_origem) VALUES
('João da Silva', '2000-05-15', 'Masculino', 'Rua A, 123, São Paulo, SP', 1500.00, 'Própria', 50, 'Pública'),
('Maria Oliveira', '2001-02-20', 'Feminino', 'Av. B, 456, Rio de Janeiro, RJ', 2000.00, 'Alugada', 0, 'Privada'),
('Carlos Pereira', '1999-11-10', 'Masculino', 'Rua C, 789, Belo Horizonte, MG', 1200.00, 'Com familiares', 100, 'Pública'),
('Ana Costa', '2002-08-01', 'Feminino', 'Rua D, 101, Salvador, BA', 2500.00, 'Alugada', 25, 'Privada'),
('Lucas Martins', '2000-03-30', 'Masculino', 'Av. E, 202, Curitiba, PR', 1800.00, 'Própria', 0, 'Pública'),
('Juliana Santos', '2001-07-12', 'Feminino', 'Rua F, 303, Porto Alegre, RS', 3000.00, 'Com familiares', 10, 'Privada'),
('Marcos Andrade', '1998-12-25', 'Masculino', 'Av. G, 404, Fortaleza, CE', 900.00, 'Alugada', 100, 'Pública'),
('Fernanda Lima', '2003-01-05', 'Feminino', 'Rua H, 505, Recife, PE', 4500.00, 'Própria', 0, 'Privada'),
('Rafael Souza', '2000-09-18', 'Masculino', 'Av. I, 606, Manaus, AM', 2200.00, 'Com familiares', 15, 'Pública'),
('Beatriz Almeida', '2001-04-22', 'Feminino', 'Rua J, 707, Brasília, DF', 1600.00, 'Alugada', 75, 'Privada');

-- Populando a tabela Alunos_Disciplina (simulando vários semestres)
INSERT INTO Alunos_Disciplina (aluno_id, disciplina_id, semestre, nota_1, nota_2, media, faltas, professores_id) VALUES
-- Aluno 1
(1, 7, '2022.1', 7.5, 8.0, 7.8, 4, 1),
(1, 1, '2022.2', 8.5, 9.0, 8.8, 2, 1),
(1, 2, '2023.1', 7.0, 6.0, 6.5, 8, 2),
(1, 5, '2023.1', 9.0, 9.5, 9.3, 1, 5),
-- Aluno 2
(2, 7, '2022.2', 9.0, 9.5, 9.3, 0, 1),
(2, 2, '2023.1', 9.5, 9.5, 9.5, 0, 2),
-- Aluno 3
(3, 1, '2023.1', 5.0, 4.5, 4.8, 15, 1), -- Reprovado
(3, 1, '2023.2', 6.0, 7.0, 6.5, 10, 1), -- Cursando de novo
(3, 8, '2023.2', 8.0, 8.0, 8.0, 3, 5),
-- Aluno 4
(4, 6, '2023.1', 7.0, 7.0, 7.0, 2, 6),
-- Aluno 5
(5, 8, '2023.1', 8.5, 7.5, 8.0, 5, 5),
-- Aluno 6
(6, 5, '2023.2', 9.0, 10.0, 9.5, 0, 5),
-- Aluno 7
(7, 4, '2023.2', 6.5, 7.5, 7.0, 6, 4),
-- Aluno 8
(8, 3, '2024.1', 8.0, 9.0, 8.5, 1, 3),
-- Aluno 9
(9, 1, '2024.1', 7.0, 7.5, 7.3, 3, 1),
-- Aluno 10
(10, 2, '2024.1', 9.0, 8.5, 8.8, 0, 2);

-- Populando a tabela Fatura (gerando faturas para vários meses)
INSERT INTO Fatura (aluno_id, valor_total, data_emissao, data_vencimento, status_fatura, desconto_aplicado) VALUES
-- Faturas Aluno 1
(1, 500.00, '2023-01-15', '2023-02-10', 'Paga', 50.00),
(1, 500.00, '2023-02-15', '2023-03-10', 'Paga', 50.00),
(1, 500.00, '2023-03-15', '2023-04-10', 'Pendente', 50.00),
-- Faturas Aluno 2
(2, 700.00, '2023-01-15', '2023-02-10', 'Paga', 0.00),
(2, 700.00, '2023-02-15', '2023-03-10', 'Atrasada', 0.00),
(2, 700.00, '2023-03-15', '2023-04-10', 'Atrasada', 0.00),
-- Faturas Aluno 3
(3, 350.00, '2023-02-15', '2023-03-10', 'Paga', 0.00),
(3, 350.00, '2023-03-15', '2023-04-10', 'Pendente', 0.00),
-- Faturas Aluno 4
(4, 800.00, '2023-03-15', '2023-04-10', 'Pendente', 200.00),
-- Faturas Aluno 7
(7, 900.00, '2023-01-15', '2023-02-10', 'Paga', 900.00),
(7, 900.00, '2023-02-15', '2023-03-10', 'Paga', 900.00),
(7, 900.00, '2023-03-15', '2023-04-10', 'Paga', 900.00);

-- Populando a tabela Pagamentos
INSERT INTO Pagamentos (fatura_id, valor, data_pagamento, forma_pagamento, tipo_pagamento) VALUES
(1, 450.00, '2023-02-08', 'Boleto', 'Mensalidade'),
(2, 450.00, '2023-03-10', 'PIX', 'Mensalidade'),
(4, 700.00, '2023-02-09', 'Cartão de Crédito', 'Mensalidade'),
(7, 350.00, '2023-03-05', 'Boleto', 'Mensalidade'),
(10, 0.00, '2023-02-10', 'Boleto', 'Matrícula'),
(11, 0.00, '2023-03-09', 'PIX', 'Matrícula'),
(12, 0.00, '2023-04-08', 'Cartão de Crédito', 'Matrícula');