CREATE OR REPLACE VIEW person_opened_categories AS
SELECT c.id, 'client' AS person_type, dlc.category, dlc.gearbox
FROM client c
JOIN driving_license dl ON c.id = dl.client_id
JOIN driving_license_category dlc ON dl.id = dlc.driving_license_id
WHERE dl.end_date > CURRENT_DATE
UNION 
SELECT i.id, 'inspector' AS person_type, dlc.category, dlc.gearbox
FROM inspector i
JOIN driving_license dl ON i.id = dl.inspector_id
JOIN driving_license_category dlc ON dl.id = dlc.driving_license_id
WHERE dl.end_date > CURRENT_DATE;

--

CREATE OR REPLACE VIEW all_tickets AS
SELECT dt.id, dt.client_id, dt.datetime, dt.status, dt.service_center_id, 'driving' AS ticket_type
FROM driving_ticket dt
UNION ALL
SELECT tt.id, tt.client_id, tt.datetime, tt.status, tt.service_center_id, 'theory' AS ticket_type
FROM theory_ticket tt;

--

CREATE OR REPLACE VIEW theory_exam_result_info AS
SELECT tt.datetime, c.id AS client_id, ter.theory_exam_id, q.text AS question, a.text AS answer, a.is_correct
FROM theory_exam_result ter
JOIN question q ON ter.question_id = q.id
JOIN answer a ON ter.selected_answer_id = a.id
JOIN theory_exam te ON ter.theory_exam_id = te.id
JOIN theory_ticket tt ON te.theory_ticket_id = tt.id
JOIN client c ON tt.client_id = c.id;
