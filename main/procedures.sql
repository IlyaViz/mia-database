CREATE OR REPLACE PROCEDURE update_expired_tickets_status()
AS $$
BEGIN
    UPDATE theory_ticket
    SET status = 'expired'
    WHERE datetime < CURRENT_TIMESTAMP - INTERVAL '1 day'
      AND status = 'pending';

    UPDATE driving_ticket
    SET status = 'expired'
    WHERE datetime < CURRENT_TIMESTAMP - INTERVAL '1 day'
      AND status = 'pending';
END;
$$ LANGUAGE plpgsql;

--

CREATE OR REPLACE PROCEDURE double_pending_fines()
AS $$
BEGIN
    UPDATE fine
    SET sum = sum * 2
    WHERE status = 'pending'
      AND issued_date < CURRENT_DATE - INTERVAL '2 week';
END;
$$ LANGUAGE plpgsql;
