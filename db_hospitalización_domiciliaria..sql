-- Creación de usuarios

CREATE TYPE tipo_usuario_enum AS ENUM ('administrador','médico/funcionario','paciente')
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    rut VARCHAR(12) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    clave VARCHAR(255) NOT NULL,
	tipo_usuario tipo_usuario_enum NOT NULL
);


CREATE TABLE medico_funcionario (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    profesion VARCHAR(50),
	telefono VARCHAR(20) NOT NULL,
	email VARCHAR(100) UNIQUE NOT NULL,
    unidad_referencia_id INT REFERENCES unidades_referencia(id)
);


CREATE TABLE pacientes (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
	direccion TEXT,
	telefono VARCHAR(20) NOT NULL,
    fecha_nacimiento DATE,
	fecha_diagnostico DATE NOT NULL
);

-- Fin usuarios

---------------------------------------------------------------

-- Relación paciente-médico y restricciones

CREATE TABLE paciente_medico (
    paciente_id INT REFERENCES pacientes(id) ON DELETE CASCADE,
    medico_id INT REFERENCES medico_funcionario(id) ON DELETE CASCADE,
    PRIMARY KEY (paciente_id, medico_id)
);


-- Trigger que limita a 3 la cantidad de médicos asignados a un paciente.
CREATE OR REPLACE FUNCTION limitar_medicos_por_paciente()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        SELECT COUNT(*) FROM paciente_medico
        WHERE paciente_id = NEW.paciente_id
    ) >= 3 THEN
        RAISE EXCEPTION 'Un paciente no puede tener más de 3 médicos asignados';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que limita a 10 los pacientes asignados a un médico
CREATE OR REPLACE FUNCTION limitar_pacientes_por_medico()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        SELECT COUNT(*) FROM paciente_medico
        WHERE medico_id = NEW.medico_id
    ) >= 10 THEN
        RAISE EXCEPTION 'Un médico no puede tener más de 10 pacientes asignados';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ambos triggers se ejecutan al crear una nueva asignación de médico-paciente o paciente-médico
CREATE TRIGGER trigger_limitar_medicos_por_paciente
BEFORE INSERT ON paciente_medico
FOR EACH ROW
EXECUTE FUNCTION limitar_medicos_por_paciente();

CREATE TRIGGER trigger_limitar_pacientes_por_medico
BEFORE INSERT ON paciente_medico
FOR EACH ROW
EXECUTE FUNCTION limitar_pacientes_por_medico();

-- Fin paciente-médico

---------------------------------------------------------------

-- Crear unidad de referencia

CREATE TYPE tipo_unidad_enum AS ENUM ('clínica','hospital','cesfam')
CREATE TABLE unidades_referencia (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT NOT NULL,
	tipo tipo_unidad_enum NOT NULL,
    telefono VARCHAR(20) NOT NULL
);

-- Fin unidad de referencia

---------------------------------------------------------------

-- Relación paciente-síntoma

CREATE TABLE sintomas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    puntuacion INT NOT NULL
);


CREATE TABLE paciente_sintoma (
    paciente_id INT REFERENCES pacientes(id) ON DELETE CASCADE,
	fecha DATE NOT NULL,
    sintoma_id INT REFERENCES sintomas(id) ON DELETE CASCADE,
    PRIMARY KEY (paciente_id, fecha, sintoma_id)
);


CREATE TYPE estado_enum AS ENUM ('verde', 'amarillo', 'rojo');
CREATE TABLE registros_sintomas_diarios (
    id SERIAL PRIMARY KEY,
    paciente_id INT REFERENCES pacientes(id),
    fecha DATE NOT NULL,
    valoracion INT NOT NULL,
	estado estado_enum NOT NULL DEFAULT 'verde',
    UNIQUE(paciente_id, fecha) 
);


-- Función que actualiza o inserta el puntaje total en registros_sintomas_diarios
CREATE OR REPLACE FUNCTION actualizar_registro_sintomas_diarios()
RETURNS TRIGGER AS $$
DECLARE
    puntaje_total INT;
BEGIN
    -- Calcular la suma total de puntuaciones para el paciente y fecha afectados
    SELECT SUM(s.puntuacion)
    INTO puntaje_total
    FROM paciente_sintoma ps
    JOIN sintomas s ON ps.sintoma_id = s.id
    WHERE ps.paciente_id = NEW.paciente_id
      AND ps.fecha = NEW.fecha;

    -- Insertar o actualizar el registro en registros_sintomas_diarios
    INSERT INTO registros_sintomas_diarios (paciente_id, fecha, valoracion)
    VALUES (NEW.paciente_id, NEW.fecha, puntaje_total)
    ON CONFLICT (paciente_id, fecha) DO UPDATE
    SET valoracion = EXCLUDED.valoracion;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que se ejecuta después de insertar o actualizar en paciente_sintoma
CREATE TRIGGER trg_actualizar_registro_sintomas_diarios
AFTER INSERT OR UPDATE ON paciente_sintoma
FOR EACH ROW
EXECUTE FUNCTION actualizar_registro_sintomas_diarios();


-- Función que asigna un color al paciente luego del registro diario de sus sintomas 
CREATE OR REPLACE FUNCTION actualizar_estado_desde_valoracion()
RETURNS TRIGGER AS $$
DECLARE
    puntaje_total INT;
    estado_semaforo estado_enum;
BEGIN
    -- Obtener la valoración actualizada del registro correspondiente
    SELECT valoracion
    INTO puntaje_total
    FROM registros_sintomas_diarios
    WHERE paciente_id = NEW.paciente_id AND fecha = NEW.fecha;

    -- Si no existe registro, no hacer nada 
    IF puntaje_total IS NULL THEN
        RETURN NEW;
    END IF;

    -- Determinar estado semáforo según valoracion
    estado_semaforo := CASE
        WHEN puntaje_total < 20 THEN 'verde'
        WHEN puntaje_total >= 20 AND puntaje_total < 50 THEN 'amarillo'
        ELSE 'rojo'
    END;

    -- Actualizar el estado en registros_sintomas_diarios
    UPDATE registros_sintomas_diarios
    SET estado = estado_semaforo
    WHERE paciente_id = NEW.paciente_id AND fecha = NEW.fecha;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger se ejecuta al actualizar el registro de síntomas diario
CREATE TRIGGER trg_actualizar_estado_desde_valoracion
AFTER INSERT OR UPDATE ON registros_sintomas_diarios
FOR EACH ROW
EXECUTE FUNCTION actualizar_estado_desde_valoracion();
-- Fin paciente-síntoma

---------------------------------------------------------------

-- Registros relevantes

CREATE TABLE indicaciones (
    id SERIAL PRIMARY KEY,
    paciente_id INT NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
    descripcion TEXT NOT NULL,          
    horarios VARCHAR(150)             
);

CREATE TABLE bitacora (
    id SERIAL PRIMARY KEY,
    paciente_id INT NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
    fecha TIMESTAMP NOT NULL DEFAULT NOW(), 
    profesional_id INT REFERENCES medico_funcionario(id) ON DELETE SET NULL,
    comentario TEXT NOT NULL
);

-- Fin registros relevantes

---------------------------------------------------------------

-- Diagnóstico y patologías asociadas

CREATE TABLE diagnosticos (
    id SERIAL PRIMARY KEY,
    paciente_id INT REFERENCES pacientes(id),
    fecha DATE NOT NULL
);

CREATE TABLE patologias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);


CREATE TABLE diagnostico_patologias (
    id SERIAL PRIMARY KEY,
    diagnostico_id INT REFERENCES diagnosticos(id) ON DELETE CASCADE,
    patologia_id INT REFERENCES patologias(id) ON DELETE CASCADE,
    UNIQUE (diagnostico_id, patologia_id)
);

-- Fin Diagnóstico y patologías asociadas

---------------------------------------------------------------

-- Alertas y botón de pánico

CREATE TABLE alertas (
    id SERIAL PRIMARY KEY,
    paciente_id INT REFERENCES pacientes(id),
    fecha DATE NOT NULL,
    motivo TEXT NOT NULL,
	registro_sintomas_id INT REFERENCES registros_sintomas_diarios(id),
    profesional_notificado INT REFERENCES medico_funcionario(id)
);

CREATE TYPE estado_alerta_enum AS ENUM ('Activa','Atendida','Cancelada')

CREATE TABLE boton_panico (
    id SERIAL PRIMARY KEY,
    paciente_id INT NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
    fecha TIMESTAMP NOT NULL DEFAULT NOW(),
    estado_alerta estado_alerta_enum NOT NULL,  
    profesional_notificado INT REFERENCES medico_funcionario(id), 
    fecha_atencion TIMESTAMP                       
);

-- Trigger para desplegar alerta a los médicos a cargo de un paciente que cambió a estado 'rojo'
CREATE OR REPLACE FUNCTION alerta_estado_rojo_multiple()
RETURNS TRIGGER AS $$
DECLARE
    medico_record RECORD;
BEGIN
    IF NEW.estado = 'rojo' AND (OLD.estado IS DISTINCT FROM 'rojo' OR OLD.estado IS NULL) THEN

        FOR medico_record IN
            SELECT medico_id FROM paciente_medico WHERE paciente_id = NEW.paciente_id LIMIT 3
        LOOP
            INSERT INTO alertas (
                paciente_id,
                fecha,
                motivo,
                registro_sintomas_id,
                profesional_notificado
            ) VALUES (
                NEW.paciente_id,
                NEW.fecha,
                'Paciente en estado ROJO según semáforo',
                NEW.id,
                medico_record.medico_id
            );
        END LOOP;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Se ejecuta al cambiar el estado del paciente
CREATE TRIGGER trg_alerta_estado_rojo_multiple
AFTER UPDATE OF estado ON registros_sintomas_diarios
FOR EACH ROW
EXECUTE FUNCTION alerta_estado_rojo_multiple();

-- Fin alertas y botón de pánico

---------------------------------------------------------------

-- Consulta para mostrar los pacientes asignados a un médico en orden según semáforo 
SELECT 
    p.id AS paciente_id,
    u.nombre AS nombre_paciente,
    rsd.fecha,
    rsd.valoracion,
    rsd.estado
FROM 
    paciente_medico pm
JOIN 
    pacientes p ON pm.paciente_id = p.id
JOIN 
    usuarios u ON p.usuario_id = u.id
LEFT JOIN 
    registros_sintomas_diarios rsd ON p.id = rsd.paciente_id AND rsd.fecha = CURRENT_DATE
WHERE 
    pm.medico_id = :medico_id  -- reemplaza :medico_id por el ID del médico consultante
ORDER BY
    CASE rsd.estado
        WHEN 'rojo' THEN 3
        WHEN 'amarillo' THEN 2
        WHEN 'verde' THEN 1
        ELSE 0  -- para pacientes sin registro de hoy
    END DESC,
    rsd.fecha DESC NULLS LAST,
    u.nombre ASC;
	
---------------------------------------------------------------
	
-- Consulta para obtener los pacientes sin registro diario
SELECT p.id, u.nombre, p.telefono
FROM pacientes p
JOIN usuarios u ON p.usuario_id = u.id
LEFT JOIN registros_sintomas_diarios rsd 
  ON p.id = rsd.paciente_id AND rsd.fecha = CURRENT_DATE
WHERE rsd.paciente_id IS NULL;