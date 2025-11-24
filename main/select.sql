-- Get clients without fines

SELECT c.*
FROM client c
JOIN driving_license dl ON c.id = dl.client_id
WHERE NOT EXISTS (
    SELECT 1
    FROM fine f
    WHERE dl.id = f.driving_license_id
);

-- Get client attempts to pass the theory exam

SELECT c.*, COUNT(*) AS attempts
FROM client c
JOIN theory_ticket tt ON c.id = tt.client_id
JOIN theory_exam te ON tt.id = te.theory_ticket_id
WHERE get_theory_exam_result(te.id) < 18
GROUP BY c.id;

-- Get clients with active fines

SELECT c.*, f.reason, f.sum
FROM client c
JOIN driving_license dl ON c.id = dl.client_id
JOIN fine f ON dl.id = f.driving_license_id
WHERE f.status = 'pending';

-- Count today new categories

SELECT category, COUNT(*)
FROM driving_exam de
JOIN driving_ticket dt ON de.driving_ticket_id = dt.id
WHERE de.exam_result = 'passed'
	AND DATE(dt.datetime) = CURRENT_DATE
GROUP BY category;

-- Get clients that got liceneses for last period of time

SELECT c.first_name, c.last_name, dl.start_date
FROM driving_license dl
JOIN client c ON dl.client_id = c.id
WHERE dl.start_date >= CURRENT_DATE - INTERVAL '3 months';

-- Get inspectors' success rates in conducting exams

SELECT i.*, COUNT(CASE WHEN de.exam_result = 'passed' THEN 1 END) * 100. / COUNT(*) AS success_rate
FROM inspector i
JOIN driving_exam de ON i.id = de.inspector_id
GROUP BY i.id
ORDER BY success_rate DESC;

-- Get inspectors conducting less than average

SELECT i.*, COUNT(*) AS total_exams
FROM inspector i
LEFT JOIN driving_exam de ON i.id = de.inspector_id
GROUP BY i.id
HAVING COUNT(*) < (
    SELECT AVG(count)
    FROM (
        SELECT COUNT(*)
        FROM driving_exam
        GROUP BY inspector_id
    )
);

-- Get clients that have not arrived for the ticket

SELECT c.*, COUNT(*)
FROM all_tickets at
JOIN client c ON at.client_id = c.id
WHERE at.status = 'expired'
GROUP BY c.id;

-- Get clients with all categories

SELECT c.*
FROM person_opened_categories poc
JOIN client c ON poc.id = c.id
WHERE poc.person_type = 'client'
GROUP BY c.id
HAVING COUNT(*) = 14;

-- Get clients whose driving license suspention period ended

SELECT c.*
FROM client c
WHERE get_person_last_active_driving_license('client', c.id) IN (
    SELECT dl.id
    FROM driving_license dl
    JOIN driving_license_status dls ON dl.id = dls.driving_license_id
    WHERE dls.status = 'suspended'
        AND dls.end_date < CURRENT_DATE
);

-- Get all theoretical questions

SELECT q.text AS question, q.photo_file_path AS question_photo_file_path, a.text AS answer, a.photo_file_path AS answer_photo_file_path, a.is_correct
FROM question q
JOIN answer a ON q.id = a.question_id;

-- Get clients categories

SELECT first_name, last_name, middle_name, category, gearbox
FROM person_opened_categories poc
JOIN client c ON poc.id = c.id
WHERE poc.person_type = 'client';

-- Get clients driving exam attempts for different category and gearbox

SELECT c.*, dt.category, dt.gearbox, COUNT(*) AS total_exams, CASE WHEN COUNT(CASE WHEN de.exam_result = 'passed' THEN 1 END) > 0 THEN 'Yes' ELSE 'No'
END AS was_successful
FROM driving_exam de
JOIN driving_ticket dt ON de.driving_ticket_id = dt.id
JOIN client c ON dt.client_id = c.id
GROUP BY c.id, dt.category, dt.gearbox;

-- Get avaiable categories and gearboxes for service centers

SELECT DISTINCT c.category, c.gearbox, sc.address, sc.number
FROM car c
JOIN service_center sc ON c.service_center_id = sc.id
WHERE car_owner = 'service'
ORDER BY number;

-- Get the most popular category and gearbox for driving exam

SELECT category, gearbox, COUNT(*) AS total
FROM driving_exam de
JOIN driving_ticket dt ON de.driving_ticket_id = dt.id
GROUP BY category, gearbox
ORDER BY total DESC;

-- Get risk clients who have multiple suspensions

SELECT c.*, COUNT(*) AS total_suspensions
FROM client c
JOIN driving_license dl ON c.id = dl.client_id
JOIN driving_license_status dls ON dl.id = dls.driving_license_id
WHERE dls.status = 'suspended'
GROUP BY c.id
HAVING COUNT(*) > 1;

-- Get theory-only service centers

SELECT sc.*
FROM service_center sc
WHERE NOT EXISTS (
		SELECT 1
		FROM car c
		WHERE c.service_center_id = sc.id
			AND c.car_owner = 'service'
	);

-- Get popular service centers

SELECT sc.*, COUNT(*) AS popularity
FROM all_tickets at
JOIN service_center sc ON at.service_center_id = sc.id
GROUP BY sc.id
ORDER BY popularity DESC;

-- Get average theory exam result by years

SELECT EXTRACT(YEAR FROM tt.datetime) AS year, AVG(get_theory_exam_result(te.id)) AS average_result
FROM theory_exam te
JOIN theory_ticket tt ON te.theory_ticket_id = tt.id
GROUP BY year
ORDER BY year;

-- Get clients last out of date document

SELECT c.*, d.type, MAX(d.end_date) AS last_out_of_date
FROM client c
JOIN document d ON c.id = d.client_id
GROUP BY c.id, d.type
HAVING MAX(d.end_date) < CURRENT_DATE;



    


       