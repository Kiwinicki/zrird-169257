SET SERVEROUTPUT ON;

-- czyszczenie widokow z poprzednich uruchomien
BEGIN
  FOR r IN (
    SELECT object_name, object_type
    FROM user_objects
    WHERE object_name IN (
      'V_WYSOKIE_PENSJE',
      'V_CW04_FINANCE',
      'V_CW04_ZAROBKI',
      'V_CW04_DZIALY',
      'V_CW04_ZAROBKI_CHECK',
      'V_MANAGEROWIE',
      'V_NAJLEPIEJ_OPLACANI'
    )
  ) LOOP
    BEGIN
      IF r.object_type = 'MATERIALIZED VIEW' THEN
        EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW ' || r.object_name;
      ELSIF r.object_type = 'VIEW' THEN
        EXECUTE IMMEDIATE 'DROP VIEW ' || r.object_name;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END LOOP;
END;
/

-- sprzatanie ewentualnych danych testowych
BEGIN
  DELETE FROM employees
  WHERE employee_id IN (9901, 9902, 9903, 9904, 9905);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/

-- ===== zad1 =====

CREATE OR REPLACE VIEW v_wysokie_pensje AS
SELECT employee_id,
       first_name,
       last_name,
       salary,
       department_id
FROM employees
WHERE salary > 6000;

-- ===== zad2 =====

CREATE OR REPLACE VIEW v_wysokie_pensje AS
SELECT employee_id,
       first_name,
       last_name,
       salary,
       department_id
FROM employees
WHERE salary > 12000;

-- ===== zad3 =====

DROP VIEW v_wysokie_pensje;

-- ===== zad4 =====

CREATE OR REPLACE VIEW v_cw04_finance AS
SELECT e.employee_id,
       e.last_name,
       e.first_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'Finance';

-- ===== zad5 =====

CREATE OR REPLACE VIEW v_cw04_zarobki AS
SELECT employee_id,
       last_name,
       first_name,
       salary,
       job_id,
       email,
       hire_date
FROM employees
WHERE salary BETWEEN 5000 AND 12000;

-- ===== zad6 - test widoku V_CW04_FINANCE =====

BEGIN
  INSERT INTO v_cw04_finance (employee_id, last_name, first_name)
  VALUES (9901, 'TEST_FINANCE', 'JAN');
  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('v_cw04_finance - INSERT: TAK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('v_cw04_finance - INSERT: NIE -> ' || SQLERRM);
    ROLLBACK;
END;
/

BEGIN
  UPDATE v_cw04_finance
  SET first_name = first_name
  WHERE employee_id = (SELECT MIN(employee_id) FROM v_cw04_finance);
  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('v_cw04_finance - UPDATE: TAK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('v_cw04_finance - UPDATE: NIE -> ' || SQLERRM);
    ROLLBACK;
END;
/

BEGIN
  DELETE FROM v_cw04_finance
  WHERE employee_id = (SELECT MIN(employee_id) FROM v_cw04_finance);
  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('v_cw04_finance - DELETE: TAK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('v_cw04_finance - DELETE: NIE -> ' || SQLERRM);
    ROLLBACK;
END;
/

-- ===== zad6 - test widoku V_CW04_ZAROBKI =====

BEGIN
  INSERT INTO v_cw04_zarobki (
    employee_id, last_name, first_name, salary, job_id, email, hire_date
  ) VALUES (
    9902, 'TEST_ZAROBKI', 'ANNA', 7000, 'SA_REP', 'AZAROBKI', DATE '2024-01-10'
  );
  DBMS_OUTPUT.PUT_LINE('v_cw04_zarobki - INSERT: TAK');

  UPDATE v_cw04_zarobki
  SET salary = 7500
  WHERE employee_id = 9902;
  DBMS_OUTPUT.PUT_LINE('v_cw04_zarobki - UPDATE: TAK');

  DELETE FROM v_cw04_zarobki
  WHERE employee_id = 9902;
  DBMS_OUTPUT.PUT_LINE('v_cw04_zarobki - DELETE: TAK');

  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('v_cw04_zarobki - blad testu: ' || SQLERRM);
    ROLLBACK;
END;
/

-- ===== zad7 =====

CREATE OR REPLACE VIEW v_cw04_dzialy AS
SELECT d.department_id,
       d.department_name,
       COUNT(e.employee_id) AS liczba_pracownikow,
       ROUND(AVG(e.salary), 2) AS srednia_pensja,
       MAX(e.salary) AS najwyzsza_pensja
FROM departments d
JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
HAVING COUNT(e.employee_id) >= 4;

-- ===== zad8 - sprawdzenie INSERT do widoku grupujacego =====

BEGIN
  INSERT INTO v_cw04_dzialy (
    department_id, department_name, liczba_pracownikow, srednia_pensja, najwyzsza_pensja
  ) VALUES (
    999, 'TEST', 4, 6000, 9000
  );
  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('v_cw04_dzialy - INSERT: TAK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('v_cw04_dzialy - INSERT: NIE -> ' || SQLERRM);
    ROLLBACK;
END;
/

-- ===== zad9 =====

CREATE OR REPLACE VIEW v_cw04_zarobki_check AS
SELECT employee_id,
       last_name,
       first_name,
       salary,
       job_id,
       email,
       hire_date
FROM employees
WHERE salary BETWEEN 5000 AND 12000
WITH CHECK OPTION;

-- ===== zad10 - WITH CHECK OPTION =====

BEGIN
  INSERT INTO v_cw04_zarobki_check (
    employee_id, last_name, first_name, salary, job_id, email, hire_date
  ) VALUES (
    9903, 'TEST_OK', 'OLA', 8000, 'SA_REP', 'OTESTOK', DATE '2024-02-01'
  );
  DBMS_OUTPUT.PUT_LINE('v_cw04_zarobki_check - INSERT pensja 8000: TAK');
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('v_cw04_zarobki_check - INSERT pensja 8000: NIE -> ' || SQLERRM);
    ROLLBACK;
END;
/

BEGIN
  INSERT INTO v_cw04_zarobki_check (
    employee_id, last_name, first_name, salary, job_id, email, hire_date
  ) VALUES (
    9904, 'TEST_NIE', 'ADAM', 13000, 'SA_REP', 'ATESTNIE', DATE '2024-02-01'
  );
  DBMS_OUTPUT.PUT_LINE('v_cw04_zarobki_check - INSERT pensja 13000: TAK');
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('v_cw04_zarobki_check - INSERT pensja 13000: NIE -> ' || SQLERRM);
    ROLLBACK;
END;
/

-- ===== zad11 =====

CREATE MATERIALIZED VIEW v_managerowie
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT e.employee_id,
       e.first_name,
       e.last_name,
       d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE e.employee_id IN (
  SELECT DISTINCT manager_id
  FROM employees
  WHERE manager_id IS NOT NULL
);

-- ===== zad12 =====

CREATE OR REPLACE VIEW v_najlepiej_oplacani AS
SELECT employee_id,
       first_name,
       last_name,
       salary
FROM (
  SELECT employee_id,
         first_name,
         last_name,
         salary,
         ROW_NUMBER() OVER (ORDER BY salary DESC, employee_id) AS rn
  FROM employees
)
WHERE rn <= 10;
