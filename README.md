# Terceridad

Este repositorio contiene la plataforma web del proyecto Terceridad, que incluye un frontend en Angular y un backend utilizando Supabase.

## Requisitos previos

- Node.js (versión 20 o superior)
- npm (normalmente viene con Node.js)
- Docker (para ejecutar Supabase localmente)

## Configuración del backend (Supabase)

### Instalación de Supabase CLI

1. Instala Supabase CLI globalmente:
   ```
   npm install -g supabase
   ```

2. Verifica la instalación:
   ```
   supabase --version
   ```

### Inicialización del proyecto Supabase

1. Descarga el repositorio del proyecto:
   ```
   git clone git@github.com:Terceridad/plataforma-web.git
   cd plataforma-web
   ```
El repositorio ya tiene la configuración de supabase.

2. Inicia los servicios de Supabase localmente:
   ```
   supabase start
   ```

### Ejecución de pruebas

Para ejecutar las pruebas del backend:

```
supabase test db
```

## Configuración del frontend (Angular)

1. Navega al directorio raíz del proyecto:
   ```
   cd plataforma-web
   ```

2. Instala las dependencias:
   ```
   npm install
   ```

3. Inicia el servidor de desarrollo:
   ```
   ng serve
   ```

4. Abre tu navegador y visita `http://localhost:4200`

## Desarrollo

1. Para trabajar en el proyecto, asegúrate de que Supabase esté ejecutándose localmente:
   ```
   supabase start
   ```

2. Desarrolla tu aplicación Angular normalmente.

3. Para aplicar cambios en la base de datos, crea nuevas migraciones:
   ```
   supabase migration new nombre_de_la_migracion
   ```

4. Aplica las nuevas migraciones:
   ```
   supabase link XXXXXXXXXX  # Remplace con el id del proyecto en la plataforma de Supabase

   supabase db push
   ```

## Contribuciones

Para las contribuciones crear un pull request.
