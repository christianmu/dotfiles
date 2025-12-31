Um **nur Bilder** einer bestimmten URL mit `wget` herunterzuladen, brauchst Du zwei Dinge:

1. **Rekursives Herunterladen** (damit wget Links verfolgt)
2. **Dateityp-Filter**, damit nur Bilder gespeichert werden

Hier sind die gängigsten Varianten.

---

# ✅ **Einfacher Befehl: Alle Bilder einer URL herunterladen**

```bash
wget -r -l1 -A jpg,jpeg,png,gif,webp https://example.com/
```

### Erklärung:

- **`-r`** → rekursiv
- **`-l1`** → Rekursionstiefe 1 (nur die Seite + direkte Links)
- **`-A`** → akzeptiere nur bestimmte Dateiendungen
- **`jpg,jpeg,png,gif,webp`** → nur Bildformate

---

# 🖼️ **Besserer Befehl (empfohlen) – holt _wirklich alle_ Bilder sauber ab**

```bash
wget -r -H -nd -np -A jpg,jpeg,png,gif,webp https://example.com/
```

### Optionen im Detail:

| Option   | Bedeutung                                                       |
| -------- | --------------------------------------------------------------- |
| `-r`     | rekursiv herunterladen                                          |
| `-H`     | domainübergreifende Hostnamen erlauben (z. B. CDN-Bilder)       |
| `-nd`    | keine Verzeichnisstruktur anlegen (alle Bilder in einem Ordner) |
| `-np`    | nicht in übergeordnete Verzeichnisse gehen                      |
| `-A ...` | Dateiendungen filtern                                           |

Damit holt wget auch Bilder von CDNs wie `/wp-content/uploads/…`, `/images/…`, `https://cdn.example.com/img/…`.

---

# 🎯 **Nur die Bilder der Startseite (kein Crawl)**

Falls Du wirklich **nur die eine HTML-Seite** analysieren willst:

```bash
wget -nd -H -A jpg,jpeg,png,gif,webp -r -l1 https://example.com/
```

---

# 🪄 **Beispiel für eine WordPress-Seite**

```bash
wget -r -nd -np -A jpg,jpeg,png,gif,webp https://example.com/wp-content/uploads/
```

Damit lädst Du **komplett alles aus /uploads/** herunter — effektiv die ganze Mediathek.

---

# 🔍 **Nur URLs sammeln, ohne zu downloaden**

Falls Du erst prüfen willst, was es gibt:

```bash
wget -r -l1 -A jpg,jpeg,png,gif,webp --spider https://example.com/ 2>&1 | grep -oP 'http[^ ]+'
```

---
