import re
import json
import sys

try:
    with open('page.html', 'r', encoding='utf-8') as f:
        html = f.read()
    
    match = re.search(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>', html)
    if match:
        json_str = match.group(1)
        data = json.loads(json_str)
        with open('hotstar_data.json', 'w') as f_out:
            json.dump(data, f_out, indent=2)
        print("Extracted JSON to hotstar_data.json")
        print("Root Keys:", list(data.keys()))
        if 'props' in data:
            print("Props Keys:", list(data['props'].keys()))
            if 'pageProps' in data['props']:
                 print("PageProps Keys:", list(data['props']['pageProps'].keys()))
    else:
        print("Not found")

except Exception as e:
    print(f"Error: {e}")
