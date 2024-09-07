CREATE TYPE gender AS ENUM ('M', 'F', 'O');

-- Tabla de usuarios de dispositivos (pacientes)
CREATE TABLE device_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES saas.tenants(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    date_of_birth DATE,
    weight DECIMAL NOT NULL,
    height DECIMAL NOT NULL,
    gender gender,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS para device_users
ALTER TABLE device_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY device_users_access_policy ON device_users
    USING (auth.uid() IN (
        SELECT user_id FROM saas.tenant_user WHERE tenant_id = device_users.tenant_id
    ));


CREATE TYPE measurement_type AS ENUM ('Frecuencia Cardiaca', 'Presion Arterial','Oxigeno en Sangre', 'Temperatura Corporal', 'Glucosa');

-- Tabla genérica para almacenar mediciones de dispositivos
CREATE TABLE device_measurements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medical_device_id UUID NOT NULL REFERENCES medical_devices(id) ON DELETE CASCADE,
    device_user_id UUID NOT NULL REFERENCES device_users(id) ON DELETE CASCADE,
    measurement_type measurement_type NOT NULL,
    measurement_value DECIMAL NOT NULL,
    unit TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS para device_measurements
ALTER TABLE device_measurements ENABLE ROW LEVEL SECURITY;
CREATE POLICY device_measurements_access_policy ON device_measurements
    USING (auth.uid() IN (
        SELECT user_id FROM saas.tenant_user ut
        JOIN iot_devices id ON ut.tenant_id = id.tenant_id
        JOIN medical_devices md ON id.id = md.iot_device_id
        WHERE md.id = device_measurements.medical_device_id
    ));


-- Tabla de relación usuario-tenant
CREATE TABLE iot_medical_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    iot_id UUID NOT NULL REFERENCES iot_devices(id) ON DELETE CASCADE,
    medical_id UUID NOT NULL REFERENCES medical_devices(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),  --last connection value
    UNIQUE(iot_id, medical_id)
);

-- RLS para user_tenants
ALTER TABLE iot_medical_devices ENABLE ROW LEVEL SECURITY;    
CREATE POLICY iot_medical_devices_access_policy ON iot_medical_devices
    USING (auth.uid() IN (
        SELECT user_id FROM saas.tenant_user ut
        JOIN iot_devices id ON ut.tenant_id = id.tenant_id
        JOIN medical_devices md ON id.id = md.iot_device_id
    ));
