#!/usr/bin/env python3
"""Gestor local de rutinas.

Sirve la interfaz y expone los archivos de ../routines como una pequeña API.
Sin dependencias: solo biblioteca estándar.

    python3 routine-manager/server.py

Escucha únicamente en 127.0.0.1: no queda expuesto a la red.
"""
import json
import re
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROUTINES = (BASE.parent / "routines").resolve()
CONFIG = (BASE.parent / "config.json").resolve()

PUERTO = 8787
NOMBRE_VALIDO = re.compile(r"^[a-z0-9][a-z0-9._-]{0,63}\.json$")
MAX_CUERPO = 1 << 20  # 1 MB

COMENTARIO = (
    "Rutina de entrenamiento. 'weeks' es cuantas semanas dura. Los dias se numeran por su "
    "orden en esta lista: el primero es el Dia 1, el segundo el Dia 2, etc. No hay fechas ni "
    "dias de la semana. Un bloque con dos ejercicios es una biserie y se encadenan sin descanso; "
    "con uno es un ejercicio suelto. 'equip' fija el tipo de peso, 'unit' la unidad y 'peso' el "
    "valor de referencia. El esfuerzo percibido (Borg) no se define aqui: se anota en la app."
)

# mismos identificadores que la tabla EQUIP de index.html
EQUIPOS = {"bw100", "bw75", "bw50", "bw25", "db1", "db2", "bar", "p1", "p2", "p4"}


def ruta_segura(nombre):
    """Devuelve la ruta del archivo solo si cae dentro de routines/."""
    if not NOMBRE_VALIDO.match(nombre or ""):
        return None
    destino = (ROUTINES / nombre).resolve()
    if destino.parent != ROUTINES:
        return None
    return destino


def texto(v, limite=200):
    return str(v or "").strip()[:limite]


def normaliza(datos):
    """Valida y limpia la rutina. Lanza ValueError con un mensaje legible."""
    if not isinstance(datos, dict):
        raise ValueError("El cuerpo debe ser un objeto JSON")

    ident = texto(datos.get("id"), 64)
    nombre = texto(datos.get("name"), 120)
    if not ident:
        raise ValueError("Falta el identificador de la rutina")
    if not nombre:
        raise ValueError("Falta el nombre de la rutina")

    try:
        semanas = int(datos.get("weeks"))
    except (TypeError, ValueError):
        raise ValueError("'weeks' debe ser un numero")
    if not 1 <= semanas <= 104:
        raise ValueError("'weeks' debe estar entre 1 y 104")

    dias_in = datos.get("days")
    if not isinstance(dias_in, list) or not dias_in:
        raise ValueError("La rutina necesita al menos un dia")

    dias = []
    # el id del ejercicio es la clave del registro en la app: repetirlo mezclaria series
    usados_dia, usados_ej = {}, {}

    def unico(base, usados):
        if base not in usados:
            usados[base] = 1
            return base
        usados[base] += 1
        return "%s-%d" % (base, usados[base])

    for i, d in enumerate(dias_in, 1):
        bloques = []
        for b in d.get("blocks") or []:
            ejercicios = []
            for e in b.get("ex") or []:
                if not texto(e.get("name")):
                    continue
                ej = {
                    "id": texto(e.get("id"), 64),
                    "name": texto(e.get("name"), 120),
                    "series": max(1, min(20, int(e.get("series") or 1))),
                    "reps": texto(e.get("reps"), 40),
                }
                equipo = texto(e.get("equip"), 16)
                if equipo:
                    if equipo not in EQUIPOS:
                        raise ValueError("Tipo de peso desconocido: " + equipo)
                    ej["equip"] = equipo
                unidad = texto(e.get("unit"), 4)
                if unidad:
                    if unidad not in ("kg", "lb"):
                        raise ValueError("Unidad desconocida: " + unidad)
                    ej["unit"] = unidad
                for opcional in ("tempo", "peso", "notes"):
                    valor = texto(e.get(opcional))
                    if valor:
                        ej[opcional] = valor
                if not ej["id"]:
                    raise ValueError("Cada ejercicio necesita identificador: " + ej["name"])
                ej["id"] = unico(ej["id"], usados_ej)
                ejercicios.append(ej)
            if not ejercicios:
                continue
            # dos ejercicios son una biserie; a partir de tres deja de tener sentido
            if len(ejercicios) > 2:
                raise ValueError("Un bloque admite como maximo dos ejercicios")
            bloques.append({
                "label": texto(b.get("label"), 60) or "Bloque",
                "ex": ejercicios,
            })
        if not bloques:
            raise ValueError("El dia %d no tiene ejercicios" % i)
        dias.append({
            "id": unico(texto(d.get("id"), 64) or ("dia-%d" % i), usados_dia),
            "name": texto(d.get("name"), 80) or ("Dia %d" % i),
            "blocks": bloques,
        })

    return {"$comment": COMENTARIO, "id": ident, "name": nombre, "weeks": semanas, "days": dias}


def registra_en_config(archivo):
    """Añade la rutina a config.json para que la app la ofrezca."""
    ruta = "routines/" + archivo
    try:
        cfg = json.loads(CONFIG.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return False
    lista = cfg.get("routines")
    if not isinstance(lista, list):
        lista = [cfg.get("routine")] if cfg.get("routine") else []
    if ruta in lista:
        return False
    lista.append(ruta)
    cfg["routines"] = lista
    CONFIG.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return True


def resumen(ruta):
    try:
        d = json.loads(ruta.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    dias = d.get("days") if isinstance(d.get("days"), list) else []
    return {
        "file": ruta.name,
        "id": d.get("id", ""),
        "name": d.get("name", ruta.name),
        "weeks": d.get("weeks", 0),
        "days": len(dias),
        "ex": sum(len(b.get("ex") or []) for dia in dias for b in dia.get("blocks") or []),
    }


class Handler(BaseHTTPRequestHandler):
    server_version = "RoutineManager/1.0"

    def log_message(self, formato, *args):
        print("  %s" % (formato % args))

    # ---- utilidades de respuesta ----
    def _envia(self, codigo, cuerpo, tipo="application/json; charset=utf-8"):
        datos = cuerpo if isinstance(cuerpo, bytes) else str(cuerpo).encode("utf-8")
        self.send_response(codigo)
        self.send_header("Content-Type", tipo)
        self.send_header("Content-Length", str(len(datos)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(datos)

    def _json(self, codigo, obj):
        self._envia(codigo, json.dumps(obj, ensure_ascii=False))

    def _error(self, codigo, mensaje):
        self._json(codigo, {"error": mensaje})

    def _lee_json(self):
        largo = int(self.headers.get("Content-Length") or 0)
        if largo <= 0 or largo > MAX_CUERPO:
            raise ValueError("Cuerpo vacio o demasiado grande")
        return json.loads(self.rfile.read(largo).decode("utf-8"))

    # ---- rutas ----
    def do_GET(self):
        if self.path in ("/", "/index.html"):
            try:
                html = (BASE / "index.html").read_bytes()
            except OSError:
                return self._error(500, "Falta routine-manager/index.html")
            return self._envia(200, html, "text/html; charset=utf-8")

        if self.path == "/api/routines":
            items = [r for r in (resumen(p) for p in sorted(ROUTINES.glob("*.json"))) if r]
            return self._json(200, {"items": items})

        if self.path.startswith("/api/routines/"):
            ruta = ruta_segura(self.path[len("/api/routines/"):])
            if not ruta:
                return self._error(400, "Nombre de archivo no valido")
            if not ruta.exists():
                return self._error(404, "No existe")
            return self._envia(200, ruta.read_bytes())

        self._error(404, "No encontrado")

    def do_PUT(self):
        if not self.path.startswith("/api/routines/"):
            return self._error(404, "No encontrado")
        archivo = self.path[len("/api/routines/"):]
        ruta = ruta_segura(archivo)
        if not ruta:
            return self._error(400, "Nombre de archivo no valido")
        try:
            datos = normaliza(self._lee_json())
        except ValueError as e:
            return self._error(400, str(e))
        except Exception:
            return self._error(400, "JSON invalido")

        nuevo = not ruta.exists()
        ruta.write_text(json.dumps(datos, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        registrada = registra_en_config(archivo) if nuevo else False
        print("  guardada %s (%d dias)" % (archivo, len(datos["days"])))
        self._json(200, {"ok": True, "file": archivo, "nueva": nuevo, "registrada": registrada})


def main():
    if not ROUTINES.is_dir():
        raise SystemExit("No encuentro la carpeta %s" % ROUTINES)
    url = "http://127.0.0.1:%d/" % PUERTO
    servidor = ThreadingHTTPServer(("127.0.0.1", PUERTO), Handler)
    print("Gestor de rutinas en %s" % url)
    print("Carpeta: %s" % ROUTINES)
    print("Ctrl+C para salir\n")
    try:
        webbrowser.open(url)
    except Exception:
        pass
    try:
        servidor.serve_forever()
    except KeyboardInterrupt:
        print("\nAdios")
        servidor.server_close()


if __name__ == "__main__":
    main()
