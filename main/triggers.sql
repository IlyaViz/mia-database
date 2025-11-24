CREATE OR REPLACE FUNCTION check_ticket_datetime()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'theory_ticket' AND NEW.datetime < CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Theory ticket datetime cannot be in the past';
    ELSIF TG_TABLE_NAME = 'driving_ticket' AND NEW.datetime < CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Driving ticket datetime cannot be in the past';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_theory_ticket_datetime_trigger
BEFORE INSERT ON theory_ticket
FOR EACH ROW
EXECUTE FUNCTION check_ticket_datetime();

CREATE TRIGGER check_driving_ticket_datetime_trigger
BEFORE INSERT ON driving_ticket
FOR EACH ROW
EXECUTE FUNCTION check_ticket_datetime();

--

CREATE OR REPLACE FUNCTION check_client_age()
RETURNS TRIGGER AS $$
BEGIN 
    IF NEW.category IN ('A', 'A1') AND get_client_age(NEW.client_id) < 16 THEN
        RAISE EXCEPTION 'Client must be at least 24 years old to get category A driving ticket';
    ELSIF NEW.category IN ('B', 'B1') AND get_client_age(NEW.client_id) < 18 THEN
        RAISE EXCEPTION 'Client must be at least 18 years old to get a driving ticket';
    ELSIF NEW.category IN ('BE', 'CE', 'C1E') AND get_client_age(NEW.client_id) < 19 THEN
        RAISE EXCEPTION 'Client must be at least 19 years old to get category BE, CE or C1E driving ticket';
    ELSIF NEW.category IN ('D', 'D1', 'DE', 'D1E', 'T') AND get_client_age(NEW.client_id) < 21 THEN
        RAISE EXCEPTION 'Client must be at least 21 years old to get category D1, D or T driving ticket';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_client_age_trigger
BEFORE INSERT ON driving_ticket
FOR EACH ROW
EXECUTE FUNCTION check_client_age();

-- 

CREATE OR REPLACE FUNCTION check_client_gets_new_category()
RETURNS TRIGGER AS $$
BEGIN 
    IF EXISTS (
        SELECT 1
        FROM person_opened_categories
        WHERE person_type = 'client'
            AND id = NEW.client_id
            AND category = NEW.category
            AND gearbox = NEW.gearbox
    ) THEN
        RAISE EXCEPTION 'Client already has the specified category and gearbox';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_client_gets_new_category_trigger
BEFORE INSERT ON driving_ticket
FOR EACH ROW
EXECUTE FUNCTION check_client_gets_new_category();

--

CREATE OR REPLACE FUNCTION check_client_has_nessesary_documents()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT person_has_active_document('client', NEW.client_id, 'passport') OR NOT person_has_active_document('client', NEW.client_id, 'registration_of_residence') THEN
        RAISE EXCEPTION 'Client must have a passport and a registration of residence';
    ELSIF TG_TABLE_NAME = 'driving_ticket' AND (NOT person_has_active_document('client', NEW.client_id, 'medical_certificate') OR NOT person_has_active_document('client', NEW.client_id, 'autoschool_certificate')) THEN
        RAISE EXCEPTION 'Client must have a medical certificate and an autoschool certificate';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_client_has_nessesary_documents_theory_trigger
BEFORE INSERT ON theory_ticket
FOR EACH ROW
EXECUTE FUNCTION check_client_has_nessesary_documents();

CREATE TRIGGER check_client_has_nessesary_documents_driving_trigger
BEFORE INSERT ON driving_ticket
FOR EACH ROW
EXECUTE FUNCTION check_client_has_nessesary_documents();

--

CREATE OR REPLACE FUNCTION check_only_one_active_ticket()
RETURNS TRIGGER AS $$
BEGIN
    IF client_has_active_ticket(NEW.client_id) THEN
        RAISE EXCEPTION 'Client can have only one active ticket';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_only_one_active_theory_ticket_trigger
BEFORE INSERT ON theory_ticket
FOR EACH ROW
EXECUTE FUNCTION check_only_one_active_ticket();

CREATE TRIGGER check_only_one_active_driving_ticket_trigger
BEFORE INSERT ON driving_ticket
FOR EACH ROW
EXECUTE FUNCTION check_only_one_active_ticket();

-- 

CREATE OR REPLACE FUNCTION check_ten_days_between_tickets()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'theory_ticket' AND EXISTS (
        SELECT 1
        FROM theory_ticket
        WHERE client_id = NEW.client_id
          AND datetime > NEW.datetime - INTERVAL '10 days'
          AND status != 'cancelled'
    ) THEN
        RAISE EXCEPTION 'Client must wait at least 10 days between theory tickets';
    ELSIF TG_TABLE_NAME = 'driving_ticket' AND EXISTS (
        SELECT 1
        FROM driving_ticket
        WHERE client_id = NEW.client_id
          AND datetime > NEW.datetime - INTERVAL '10 days'
          AND status != 'cancelled'
    ) THEN
        RAISE EXCEPTION 'Client must wait at least 10 days between driving tickets';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_ten_days_between_theory_tickets_trigger
BEFORE INSERT ON theory_ticket
FOR EACH ROW
EXECUTE FUNCTION check_ten_days_between_tickets();

CREATE TRIGGER check_ten_days_between_driving_tickets_trigger
BEFORE INSERT ON driving_ticket
FOR EACH ROW
EXECUTE FUNCTION check_ten_days_between_tickets();

-- 

CREATE OR REPLACE FUNCTION check_client_has_active_passed_theory_exam()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT client_has_active_passed_theory_exam(NEW.client_id) THEN
        RAISE EXCEPTION 'Client must have passed the theory exam';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_client_has_active_passed_theory_exam_trigger
BEFORE INSERT ON driving_ticket
FOR EACH ROW
EXECUTE FUNCTION check_client_has_active_passed_theory_exam();

--

CREATE OR REPLACE FUNCTION update_ticket_status_after_exam_creation()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'theory_exam' THEN
        UPDATE theory_ticket
        SET status = 'used'
        WHERE id = NEW.theory_ticket_id;
    ELSIF TG_TABLE_NAME = 'driving_exam' THEN
        UPDATE driving_ticket
        SET status = 'used'
        WHERE id = NEW.driving_ticket_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_theory_ticket_status_trigger
AFTER INSERT ON theory_exam
FOR EACH ROW
EXECUTE FUNCTION update_ticket_status_after_exam_creation();

CREATE TRIGGER update_driving_ticket_status_trigger
AFTER INSERT ON driving_exam
FOR EACH ROW
EXECUTE FUNCTION update_ticket_status_after_exam_creation();

--

CREATE OR REPLACE FUNCTION check_car_availability()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.car_owner = 'service' AND NOT EXISTS (
        SELECT 1
        FROM car
        WHERE service_center_id = NEW.service_center_id
          AND gearbox = NEW.gearbox
          AND category = NEW.category
          AND car_owner = 'service'
    ) THEN
        RAISE EXCEPTION 'No available car with the specified gearbox and category at the service center';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_car_availability_trigger
BEFORE INSERT ON driving_ticket
FOR EACH ROW
EXECUTE FUNCTION check_car_availability();

--

CREATE OR REPLACE FUNCTION check_car_is_appropriate()
RETURNS TRIGGER AS $$
DECLARE
    driving_ticket_category VARCHAR(255);
    driving_ticket_gearbox VARCHAR(255);
    
    car_category VARCHAR(255);
    car_gearbox VARCHAR(255);
BEGIN
    IF NEW.car_id IS NOT NULL THEN
        SELECT category, gearbox INTO driving_ticket_category, driving_ticket_gearbox 
        FROM driving_ticket
        WHERE id = NEW.driving_ticket_id;

        SELECT category, gearbox INTO car_category, car_gearbox
        FROM car
        WHERE id = NEW.car_id;

        IF driving_ticket_category != car_category OR driving_ticket_gearbox != car_gearbox THEN
            RAISE EXCEPTION 'Car is not appropriate for the driving ticket';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_car_is_appropriate_trigger
BEFORE INSERT OR UPDATE ON driving_exam
FOR EACH ROW
EXECUTE FUNCTION check_car_is_appropriate();

--

CREATE OR REPLACE FUNCTION check_inspector_capability()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM person_opened_categories
        WHERE person_type = 'inspector'
            AND id = NEW.inspector_id
            AND category = (SELECT category FROM driving_ticket dt WHERE dt.id = NEW.driving_ticket_id)
            AND gearbox = (SELECT gearbox FROM driving_ticket dt WHERE dt.id = NEW.driving_ticket_id)
    ) THEN
        RAISE EXCEPTION 'Inspector does not have the necessary category';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_inspector_capability_trigger
BEFORE INSERT ON driving_exam
FOR EACH ROW
EXECUTE FUNCTION check_inspector_capability();

--

CREATE OR REPLACE FUNCTION check_inspector_has_necessary_documents()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT person_has_active_document('inspector', NEW.inspector_id, 'inspector_certificate') THEN
        RAISE EXCEPTION 'Inspector must have an inspector certificate';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_inspector_has_neccecery_documents_trigger
BEFORE INSERT ON driving_exam
FOR EACH ROW
EXECUTE FUNCTION check_inspector_has_necessary_documents();

--

CREATE OR REPLACE FUNCTION create_driving_license_or_add_category_after_driving_exam()
RETURNS TRIGGER AS $$
DECLARE
    client_id INT;
    last_active_driving_license_id INT;
BEGIN
    IF NEW.exam_result != 'passed' THEN
        RETURN NEW;
    END IF;

    SELECT dt.client_id INTO client_id 
    FROM driving_ticket dt
    WHERE id = NEW.driving_ticket_id;

    last_active_driving_license_id = get_person_last_active_driving_license('client', client_id);

    IF last_active_driving_license_id IS NULL THEN
        INSERT INTO driving_license (end_date, client_id)
        VALUES (CURRENT_DATE + INTERVAL '2 year', client_id);

        last_active_driving_license_id = get_person_last_active_driving_license('client', client_id);
    END IF;

    INSERT INTO driving_license_category (category, gearbox, driving_license_id)
    VALUES ((SELECT category FROM driving_ticket WHERE id = NEW.driving_ticket_id), (SELECT gearbox FROM driving_ticket WHERE id = NEW.driving_ticket_id), last_active_driving_license_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_driving_license_or_add_category_after_driving_exam_trig
AFTER INSERT OR UPDATE ON driving_exam
FOR EACH ROW
EXECUTE FUNCTION create_driving_license_or_add_category_after_driving_exam();
