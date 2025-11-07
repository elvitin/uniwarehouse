-- =====================================================================
-- Script de ETL (Extração, Transformação e Carga)
-- Objetivo: Popular o Data Warehouse a partir do banco de dados transacional.
-- =====================================================================

-- =====================================================================
-- PASSO 1: CARGA DAS TABELAS DE DIMENSÃO
-- =====================================================================

-- -----------------------------------------------------
-- Carga da Dim_Tempo
-- Gera uma série de datas para um período relevante (ex: 2020 a 2025)
-- -----------------------------------------------------
INSERT INTO Dim_Tempo (data, ano, semestre, trimestre, mes, nome_mes, dia_semana, nome_dia_semana, ano_semestre)
SELECT
    datum AS data,
    EXTRACT(YEAR FROM datum) AS ano,
    CASE WHEN EXTRACT(MONTH FROM datum) <= 6 THEN 1 ELSE 2 END AS semestre,
    EXTRACT(QUARTER FROM datum) AS trimestre,
    EXTRACT(MONTH FROM datum) AS mes,
    TO_CHAR(datum, 'TMMonth') AS nome_mes,
    EXTRACT(ISODOW FROM datum) AS dia_semana,
    TO_CHAR(datum, 'TMDay') AS nome_dia_semana,
    CONCAT(EXTRACT(YEAR FROM datum), '.', CASE WHEN EXTRACT(MONTH FROM datum) <= 6 THEN '1' ELSE '2' END) AS ano_semestre
FROM GENERATE_SERIES('2020-01-01'::DATE, '2025-12-31'::DATE, '1 day'::INTERVAL) datum;


-- -----------------------------------------------------
-- Carga da Dim_Curso
-- -----------------------------------------------------
INSERT INTO Dim_Curso (nk_curso, nome, nivel, forma_oferta, turno, duracao_semestres)
SELECT
    id,
    nome,
    nivel,
    forma_oferta,
    turno,
    duracao
FROM Cursos;

-- -----------------------------------------------------
-- Carga da Dim_Disciplina
-- -----------------------------------------------------
INSERT INTO Dim_Disciplina (nk_disciplina, nome, carga_horaria_total)
SELECT
    id,
    nome,
    carga_horaria_total
FROM Disciplinas;

-- -----------------------------------------------------
-- Carga da Dim_Professor
-- -----------------------------------------------------
INSERT INTO Dim_Professor (nk_professor, nome, titulacao, area_atuacao)
SELECT
    id,
    nome,
    titulacao,
    area_atuacao
FROM Professores;

-- -----------------------------------------------------
-- Carga da Dim_Aluno
-- Inclui transformações para faixa etária, faixa de renda e status.
-- -----------------------------------------------------
INSERT INTO Dim_Aluno (nk_aluno, nome_completo, sexo, faixa_etaria, faixa_renda, moradia, possui_bolsa, percentual_bolsa, tipo_escolar_origem, status_evasao, data_desligamento)
SELECT
    id,
    nome_completo,
    sexo,
    CASE
        WHEN (EXTRACT(YEAR FROM AGE(data_nascimento))) BETWEEN 16 AND 20 THEN '16-20 anos'
        WHEN (EXTRACT(YEAR FROM AGE(data_nascimento))) BETWEEN 21 AND 25 THEN '21-25 anos'
        WHEN (EXTRACT(YEAR FROM AGE(data_nascimento))) BETWEEN 26 AND 30 THEN '26-30 anos'
        WHEN (EXTRACT(YEAR FROM AGE(data_nascimento))) > 30 THEN 'Mais de 30 anos'
        ELSE 'Não informado'
    END AS faixa_etaria,
    CASE
        WHEN renda <= 1500 THEN 'Até R$1.500'
        WHEN renda > 1500 AND renda <= 3000 THEN 'R$1.501 - R$3.000'
        WHEN renda > 3000 AND renda <= 5000 THEN 'R$3.001 - R$5.000'
        WHEN renda > 5000 THEN 'Acima de R$5.000'
        ELSE 'Não informado'
    END AS faixa_renda,
    moradia,
    (bolsa > 0) AS possui_bolsa,
    bolsa AS percentual_bolsa,
    tipo_escolar_origem,
    (data_desligamento IS NOT NULL) AS status_evasao,
    data_desligamento
FROM Alunos;


-- =====================================================================
-- PASSO 2: CARGA DAS TABELAS FATO
-- =====================================================================

-- -----------------------------------------------------
-- Carga da Fato_Academico
-- Junta dados de várias tabelas e busca as chaves nas dimensões.
-- -----------------------------------------------------
INSERT INTO Fato_Academico (id_aluno, id_disciplina, id_curso, id_professor, id_tempo_semestre, semestre_label, nota_1, nota_2, media_final, faltas, status_aprovacao)
WITH AlunoCurso AS (
    -- Subquery para associar um aluno a um curso com base na primeira disciplina cursada
    SELECT DISTINCT ON (ad.aluno_id)
        ad.aluno_id,
        dhc.curso_id
    FROM Alunos_Disciplina ad
    JOIN Disciplinas_has_Cursos dhc ON ad.disciplina_id = dhc.disciplina_id
    ORDER BY ad.aluno_id, ad.semestre
)
SELECT
    da.id_aluno,
    dd.id_disciplina,
    dc.id_curso,
    dp.id_professor,
    dt.id_tempo,
    ad.semestre AS semestre_label,
    ad.nota_1,
    ad.nota_2,
    ad.media,
    ad.faltas,
    CASE
        WHEN ad.media >= 7.0 AND ad.faltas <= (ddp.carga_horaria_total * 0.25) THEN 'Aprovado'
        WHEN ad.media < 7.0 THEN 'Reprovado por Nota'
        WHEN ad.faltas > (ddp.carga_horaria_total * 0.25) THEN 'Reprovado por Falta'
        ELSE 'Em Curso'
    END AS status_aprovacao
FROM Alunos_Disciplina ad
JOIN Dim_Aluno da ON ad.aluno_id = da.nk_aluno
JOIN Dim_Disciplina dd ON ad.disciplina_id = dd.nk_disciplina
JOIN Disciplinas ddp ON ad.disciplina_id = ddp.id -- Join para pegar a carga horária
LEFT JOIN Dim_Professor dp ON ad.professores_id = dp.nk_professor
LEFT JOIN AlunoCurso ac ON ad.aluno_id = ac.aluno_id
LEFT JOIN Dim_Curso dc ON ac.curso_id = dc.nk_curso
LEFT JOIN Dim_Tempo dt ON ad.semestre = dt.ano_semestre AND dt.mes IN (6, 12) AND dt.dia_semana = 1; -- Associa ao início da semana do último mês do semestre


-- -----------------------------------------------------
-- Carga da Fato_Financeiro
-- -----------------------------------------------------
INSERT INTO Fato_Financeiro (nk_fatura, id_aluno, id_tempo_emissao, id_tempo_vencimento, valor_total, desconto_aplicado, valor_final, status_fatura, dias_atraso)
SELECT
    f.id AS nk_fatura,
    da.id_aluno,
    dte.id_tempo AS id_tempo_emissao,
    dtv.id_tempo AS id_tempo_vencimento,
    f.valor_total,
    f.desconto_aplicado,
    (f.valor_total - f.desconto_aplicado) AS valor_final,
    f.status_fatura,
    CASE
        WHEN f.status_fatura = 'Atrasada' AND p.data_pagamento IS NULL THEN (CURRENT_DATE - f.data_vencimento::DATE)
        WHEN f.status_fatura = 'Atrasada' AND p.data_pagamento IS NOT NULL THEN (p.data_pagamento::DATE - f.data_vencimento::DATE)
        ELSE 0
    END AS dias_atraso
FROM Fatura f
JOIN Dim_Aluno da ON f.aluno_id = da.nk_aluno
LEFT JOIN Pagamentos p ON f.id = p.fatura_id
LEFT JOIN Dim_Tempo dte ON f.data_emissao::DATE = dte.data
LEFT JOIN Dim_Tempo dtv ON f.data_vencimento::DATE = dtv.data;
