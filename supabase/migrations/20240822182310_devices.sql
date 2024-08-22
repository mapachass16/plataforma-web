-- Tabla de dispositivos IoT
CREATE TABLE iot_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES saas.tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    device_type TEXT NOT NULL,
    serial_number TEXT UNIQUE NOT NULL,
    firmware_version TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS device_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);


-- Tabla de wearables y dispositivos médicos
CREATE TABLE medical_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    iot_device_id UUID NOT NULL REFERENCES iot_devices(id) ON DELETE CASCADE,    
    device_type UUID NOT NULL REFERENCES device_types(id) ON DELETE CASCADE ,
    name TEXT NOT NULL,
    serial_number TEXT UNIQUE NOT NULL,
    manufacturer TEXT,
    model TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS device_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medical_device_id UUID NOT NULL REFERENCES medical_devices(id) ON DELETE CASCADE,
    config_key TEXT NOT NULL,
    config_value TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(medical_device_id, config_key)
);
-- RLS para device_configurations
ALTER TABLE device_configurations ENABLE ROW LEVEL SECURITY;
