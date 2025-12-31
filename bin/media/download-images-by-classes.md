**Mit wget allein geht das nicht.**
`wget` kann **nicht** nach CSS-Klassen filtern, weil es nur Dateien anhand von **Dateiendungen / URLs** herunterlädt — nicht nach HTML-Inhalten.

Aber:
👉 Du _kannst_ das erreichen, indem Du **HTML → Bilder extrahierst → dann die gefundenen URLs mit wget lädst**.

Die drei üblichen Lösungen:

---

# ❌ **Direkt mit wget – geht nicht**

Beispielsweise sowas wäre **nicht möglich**:

```
wget --class=featured-media
```

Das gibt es nicht.
wget kennt nur:

- Dateiendungen (`-A`),
- Domains,
- Rekursionstiefe,
- Pfade.

Aber **keine HTML-Analyse**.

---

# ✅ **1. Lösung: HTML auslesen → Bild-URLs extrahieren → wget downloaden**

```bash
curl -s "https://www.singer.com/products/husqvarnaviking-quilting-kit" \
  | grep -oP '<img[^>]*>' \
  | grep -i 'featured-media' \
  | grep -oP 'src="\K[^"]+' \
  | sed 's|^//|https://|' \
  | xargs -r -n1 wget -nc

```

---

# 🔧 **2. Alternative (lesbar): kleines Python-Script verwenden**

Wenn Du etwas Sauberes möchtest:

```python
import requests
from bs4 import BeautifulSoup
import os
import urllib.request

url = "https://example.com"
html = requests.get(url).text
soup = BeautifulSoup(html, "html.parser")

for img in soup.find_all("img", class_="featured-media"):
    src = img.get("src")
    if src:
        print("Downloading:", src)
        urllib.request.urlretrieve(src, os.path.basename(src))
```

**Starten mit:**

```bash
python3 download_featured_media.py
```

---

# 🎯 **3. Einfachste Bash-Lösung ohne Python**

→ benötigt das kleine Tool **pup**, das HTML lesen kann.

```bash
URL="https://www.singer.com/products/husqvarnaviking-quilting-kit"
CLASS="featured-media"
SCHEME="${URL%%:*}"

curl -s "$URL" \
  | pup "img.${CLASS} attr{src}" \
  | sed "s|^//|${SCHEME}://|" \
  | xargs -n1 wget -nc

```

---
