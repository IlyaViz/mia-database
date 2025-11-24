CREATE OR REPLACE FUNCTION get_client_age(client_id INT)
RETURNS INT AS $$
BEGIN
    RETURN (
        SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth))
        FROM client
        WHERE id = $1
    );
END;
$$ LANGUAGE plpgsql;

-- 

CREATE OR REPLACE FUNCTION client_has_active_ticket(client_id INT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM all_tickets at
        WHERE at.client_id = $1
            AND status = 'pending'
    );
END;
$$ LANGUAGE plpgsql;

--

CREATE OR REPLACE FUNCTION get_theory_exam_result(theory_exam_id INT)
RETURNS INT AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM theory_exam_result_info teri
        WHERE teri.theory_exam_id = $1
            AND teri.is_correct = TRUE
    );
END;
$$ LANGUAGE plpgsql;

-- 

CREATE OR REPLACE FUNCTION client_has_active_passed_theory_exam(client_id INT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM theory_exam te
        JOIN theory_ticket tt ON te.theory_ticket_id = tt.id
        WHERE tt.client_id = $1
            AND get_theory_exam_result(te.id) >= 18
            AND CURRENT_DATE - INTERVAL '2 years' < tt.datetime
    );
END;
$$ LANGUAGE plpgsql;

--

CREATE OR REPLACE FUNCTION person_has_active_document(person_type VARCHAR(255), person_id INT, doc_type document_type)
RETURNS BOOLEAN AS $$
BEGIN
    IF person_type = 'client' THEN
        RETURN EXISTS (
            SELECT 1
            FROM document d
            WHERE d.client_id = $2
                AND d.type = $3
                AND end_date > CURRENT_DATE
        );
    ELSIF person_type = 'inspector' THEN
        RETURN EXISTS (
            SELECT 1
            FROM document d
            WHERE d.inspector_id = $2
                AND d.type = $3
                AND end_date > CURRENT_DATE
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

--

CREATE OR REPLACE FUNCTION get_person_last_active_driving_license(person_type VARCHAR(255), person_id INT)
RETURNS INT AS $$
DECLARE
    last_driving_license_id INT;
BEGIN
    IF $1 = 'client' THEN
        SELECT MAX(dl.id) INTO last_driving_license_id
        FROM driving_license dl
        WHERE dl.client_id = $2
            AND dl.end_date > CURRENT_DATE
            AND NOT EXISTS (
                SELECT 1 
                FROM driving_license_status dls
                WHERE dls.driving_license_id = dl.id
                    AND dls.status = 'revoked'
            );
    ELSE 
        SELECT MAX(dl.id) INTO last_driving_license_id
        FROM driving_license dl
        WHERE dl.inspector_id = $2
            AND dl.end_date > CURRENT_DATE
            AND NOT EXISTS (
                SELECT 1 
                FROM driving_license_status dls
                WHERE dls.driving_license_id = dl.id
                    AND dls.status = 'revoked'
            );
    END IF;

    RETURN last_driving_license_id;
END;
$$ LANGUAGE plpgsql;

--

CREATE OR REPLACE FUNCTION get_tickets_count_for_day(day DATE, service_center_id INT)
RETURNS TABLE(theory_tickets_count BIGINT, driving_tickets_count BIGINT) AS $$
BEGIN
    RETURN QUERY SELECT 
        COUNT(CASE WHEN at.ticket_type = 'theory' THEN 1 END) AS theory_tickets_count, COUNT(CASE WHEN at.ticket_type = 'driving' THEN 1 END) AS driving_tickets_count
        FROM all_tickets at
        WHERE DATE(at.datetime) = $1
            AND at.service_center_id = $2;
END;
$$ LANGUAGE plpgsql;

--

CREATE OR REPLACE FUNCTION get_appropriate_inspectors_for_driving_exam(driving_ticket_id INT)
RETURNS TABLE(inspector_id INT, inspector_name TEXT) AS $$
BEGIN
    RETURN QUERY SELECT 
        i.id, i.first_name || ' ' || i.last_name || ' ' || i.middle_name
        FROM inspector i
        JOIN service_center sc ON i.service_center_id = sc.id
        JOIN driving_ticket dt ON sc.id = dt.service_center_id
        JOIN person_opened_categories poc ON i.id = poc.id
        WHERE dt.id = $1
            AND poc.person_type = 'inspector'
            AND poc.category = dt.category
            AND poc.gearbox = dt.gearbox
            AND person_has_active_document('inspector', i.id, 'inspector_certificate');
END;
$$ LANGUAGE plpgsql;

-- 

CREATE OR REPLACE FUNCTION get_new_theory_exam_questions(client_id INT)
RETURNS TABLE(question_id INT, question_text VARCHAR(500), photo_file_path VARCHAR(255)) AS $$
BEGIN
    DROP TABLE IF EXISTS left_questions;

    CREATE TEMP TABLE left_questions AS
    SELECT q.id, q.text, q.photo_file_path
    FROM question q
    WHERE q.text NOT IN (
        SELECT question 
        FROM theory_exam_result_info teri
        WHERE teri.client_id = $1
    )
    ORDER BY RANDOM()
    LIMIT 20;

    IF (SELECT COUNT(*) FROM left_questions) = 20 THEN
        RETURN QUERY SELECT * FROM left_questions;
    ELSE
        RETURN QUERY SELECT q.id, q.text, q.photo_file_path 
            FROM question q
            ORDER BY RANDOM() 
            LIMIT 20;
    END IF;
END;
$$ LANGUAGE plpgsql;
