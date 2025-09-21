from flask import Flask, request, Response, jsonify
from weasyprint import HTML, CSS
from weasyprint.text.fonts import FontConfiguration
import json
import io
import tempfile
import os
from datetime import datetime
import pytz

app = Flask(__name__)

def convert_json_to_html(data):
    """Convert JSON data to HTML format with new layout including sentence data"""
    
    # Debug: Print the data structure
    print(f"DEBUG: Data type: {type(data)}")
    print(f"DEBUG: Data content: {data}")
    
    # Extract the data from different JSON structures
    if isinstance(data, list) and len(data) > 0:
        # Handle list format - take first item
        first_item = data[0]
        print(f"DEBUG: First item: {first_item}")
        
        # Ensure first_item is a dictionary
        if not isinstance(first_item, dict):
            print(f"DEBUG: First item is not a dict, type: {type(first_item)}")
            first_item = {}
        
        if 'output' in first_item:
            items = first_item['output']
        elif 'data' in first_item:
            items = first_item['data']
        elif 'words' in first_item:
            items = first_item['words']
        else:
            items = [first_item]
        
        # Get message from first item
        message = ''
        title = None
        time = None
        sentence_data = []
        
        print(f"DEBUG: Processing first_item with keys: {first_item.keys() if isinstance(first_item, dict) else 'Not a dict'}")
        
        if 'message' in first_item:
            print(f"DEBUG: Found 'message' key in first_item")
            if isinstance(first_item['message'], dict):
                print(f"DEBUG: 'message' is a dict with keys: {first_item['message'].keys()}")
                # Handle nested message structure
                if 'content' in first_item['message']:
                    message = first_item['message']['content']
                    print(f"DEBUG: Found 'content' in message: {message[:100]}...")
                # Check if time is inside message object
                if 'time' in first_item['message']:
                    time = first_item['message']['time']
                    print(f"DEBUG: Found 'time' in message: {time}")
                # Check if title is inside message object
                if 'title' in first_item['message']:
                    title = first_item['message']['title']
                    print(f"DEBUG: Found 'title' in message: {title}")
                # Check if sentence data is inside message object
                if 'sentence' in first_item['message']:
                    try:
                        sentence_data = json.loads(first_item['message']['sentence'])
                        print(f"DEBUG: Found 'sentence' data with {len(sentence_data)} items")
                    except (json.JSONDecodeError, TypeError) as e:
                        print(f"DEBUG: Error parsing sentence data: {e}")
                        sentence_data = []
            elif isinstance(first_item['message'], str):
                message = first_item['message']
                print(f"DEBUG: 'message' is a string: {message[:100]}...")
        else:
            print(f"DEBUG: No 'message' key found in first_item")
        
        # Get title and time from first item
        print(f"DEBUG: Before fallback - Title: {title}, Time: {time}")
        
        # If title wasn't found in message, try root level
        if not title:
            title = first_item.get("title", "No Title")
            print(f"DEBUG: Title not found in message, using root level: {title}")
        # If time wasn't found in message, try root level
        if not time:
            time = first_item.get("time", "")
            print(f"DEBUG: Time not found in message, using root level: {time}")
        
        print(f"DEBUG: Final values - Title: '{title}', Time: '{time}', Sentence data items: {len(sentence_data)}")
        
    elif isinstance(data, dict):
        # Handle dictionary format
        if 'output' in data:
            items = data['output']
        elif 'data' in data:
            items = data['data']
        elif 'words' in data:
            items = data['words']
        else:
            items = [data]
        
        # Get message if available
        message = ''
        title = None
        time = None
        sentence_data = []
        
        print(f"DEBUG: Processing dict data with keys: {data.keys()}")
        
        if 'message' in data:
            print(f"DEBUG: Found 'message' key in data")
            if isinstance(data['message'], dict):
                print(f"DEBUG: 'message' is a dict with keys: {data['message'].keys()}")
                # Handle nested message structure
                if 'content' in data['message']:
                    message = data['message']['content']
                    print(f"DEBUG: Found 'content' in message: {message[:100]}...")
                # Check if time is inside message object
                if 'time' in data['message']:
                    time = data['message']['time']
                    print(f"DEBUG: Found 'time' in message: {time}")
                # Check if title is inside message object
                if 'title' in data['message']:
                    title = data['message']['title']
                    print(f"DEBUG: Found 'title' in message: {title}")
                # Check if sentence data is inside message object
                if 'sentence' in data['message']:
                    try:
                        sentence_data = json.loads(data['message']['sentence'])
                        print(f"DEBUG: Found 'sentence' data with {len(sentence_data)} items")
                    except (json.JSONDecodeError, TypeError) as e:
                        print(f"DEBUG: Error parsing sentence data: {e}")
                        sentence_data = []
            elif isinstance(data['message'], str):
                message = data['message']
                print(f"DEBUG: 'message' is a string: {message[:100]}...")
        else:
            print(f"DEBUG: No 'message' key found in data")
        
        # Get title and time
        print(f"DEBUG: Before fallback - Title: {title}, Time: {time}")
        
        # If title wasn't found in message, try root level
        if not title:
            title = data.get("title", "No Title")
            print(f"DEBUG: Title not found in message, using root level: {title}")
        # If time wasn't found in message, try root level
        if not time:
            time = data.get("time", "")
            print(f"DEBUG: Time not found in message, using root level: {time}")
        
        print(f"DEBUG: Final values - Title: '{title}', Time: '{time}', Sentence data items: {len(sentence_data)}")
    else:
        items = [data]
        message = ''
        title = "No Title"
        time = ""
        sentence_data = []

    # Convert time from GMT to GMT+6
    current_time = ''
    if time:
        try:
            dt = datetime.fromisoformat(time.replace('Z', '+00:00'))
            gmt6 = pytz.timezone('Asia/Dhaka')
            local_time = dt.astimezone(gmt6)
            current_time = local_time.strftime('%Y-%m-%d %H:%M:%S GMT+6')
        except Exception:
            current_time = 'Time conversion error'
    else:
        # Use current time in GMT+6 if no time provided
        gmt6 = pytz.timezone('Asia/Dhaka')
        current_time = datetime.now(gmt6).strftime('%Y-%m-%d %H:%M:%S GMT+6')
    
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>AI Powered English Learning Notes - {title}</title>
        <style>
            @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;500;700&display=swap');
            
            @page {
                size: A4 portrait;
                margin: 10mm;
            }
            
            body {
                font-family: 'Arial', 'Noto Sans Bengali', sans-serif;
                margin: 0;
                padding: 15px;
                background-color: white;
                color: #333;
                line-height: 1.4;
                font-size: 20px; /* Increased base font size for body text */
            }
            
            .header {
                text-align: center;
                margin-bottom: 20px;
                border-bottom: 3px solid #2c3e50;
                padding-bottom: 15px;
            }
            
            .main-title {
                font-size: 28px; /* Increased for larger main title */
                font-weight: bold;
                color: #2c3e50;
                margin-bottom: 8px;
            }
            
            .news-title {
                font-size: 24px; /* Increased for larger news title */
                font-weight: bold;
                color: #e74c3c;
                margin-bottom: 8px;
                text-align: center;
            }
            
            .time-info {
                font-size: 16px; /* Increased for better readability */
                color: #7f8c8d;
                text-align: center;
                margin-bottom: 15px;
            }
            
            .section {
                margin-bottom: 22px;
                page-break-inside: avoid;
            }
            
            .section-title {
                font-size: 18px; /* Increased for section titles */
                font-weight: bold;
                color: #2c3e50;
                margin-bottom: 12px;
                border-bottom: 2px solid #3498db;
                padding-bottom: 5px;
            }
            
            .table-container {
                width: 100%;
                overflow-x: auto;
            }
            
            table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 20px;
            }
            
            th, td {
                border: 1px solid #ddd;
                padding: 8px; /* Increased padding for better spacing */
                text-align: left;
                font-size: 16px; /* Increased for table content */
                vertical-align: middle;
            }
            
            th {
                background-color: #3498db;
                color: white;
                font-weight: bold;
            }
            
            tr:nth-child(even) {
                background-color: #f2f2f2;
            }
            
            .bengali-text {
                font-family: 'Noto Sans Bengali', 'Arial', sans-serif;
                text-align: left;
                font-size: 16px; /* Explicitly set for Bengali text */
            }
            
            .synonyms, .antonyms {
                font-size: 16px; /* Increased for synonyms/antonyms */
                text-align: left;
            }
            
            .synonyms {
                color: #27ae60;
            }
            
            .antonyms {
                color: #e74c3c;
            }
            
            .translation-section {
                margin-top: 20px;
            }
            
            .translation-content {
                background-color: #f8f9fa;
                padding: 12px;
                border-radius: 8px;
                border-left: 4px solid #3498db;
                font-size: 20px; /* Increased for translation text */
                line-height: 1.6;
                text-align: justify;
            }
            
            .english-text {
                font-size: 20px;
            }
            
            .bengali-translation {
                font-family: 'Noto Sans Bengali', 'Arial', sans-serif;
                direction: rtl;
                text-align: right;
                margin-top: 10px;
                padding-top: 10px;
                border-top: 1px solid #ddd;
                font-size: 14px; /* Explicitly set for Bengali translation */
            }
            
            .sentence-example {
                background-color: #f0f8ff;
                padding: 8px;
                border-radius: 4px;
                margin: 4px 0;
                font-size: 14px;
                line-height: 1.4;
            }
            
            .sentence-example-en {
                color: #2c3e50;
                font-weight: 500;
            }
            
            .sentence-example-bn {
                color: #7f8c8d;
                font-style: italic;
            }
            
            .footer {
                text-align: center;
                margin-top: 20px;
                padding-top: 15px;
                border-top: 1px solid #e0e0e0;
                color: #7f8c8d;
                font-size: 13px; /* Increased for footer */
            }
        </style>
    </head>
    <body>
    """
    
    # Add vocabulary table section
    html_content += f"""
            <div class="header">
            <div class="main-title">AI Powered English Learning Notes from contemporary news</div>
            <div class="news-title">{title}</div>
            <div class="time-info">{current_time}</div>
        </div>
        <div class="section">
            <div class="section-title">Vocabulary Table</div>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>S/N</th>
                            <th>Word</th>
                            <th>Meaning in Bengali</th>
                            <th>Synonyms</th>
                            <th>Antonyms</th>
                        </tr>
                    </thead>
                    <tbody>
    """
    
    for i, item in enumerate(items, 1):
        if isinstance(item, dict):
            english = item.get('english', '')
            bengali = item.get('bengali', '')
            synonyms = item.get('synonyms', [])
            antonyms = item.get('antonyms', [])
            
            html_content += f"""
                        <tr>
                            <td>{i}</td>
                            <td><strong>{english}</strong></td>
                            <td class="bengali-text">{bengali}</td>
                            <td class="synonyms">{', '.join(synonyms)}</td>
                            <td class="antonyms">{', '.join(antonyms)}</td>
                        </tr>
            """
    
    html_content += """
                    </tbody>
                </table>
            </div>
        </div>
    """
    
    # Add sentence examples table if sentence data exists
    if sentence_data:
        html_content += """
        <div class="section">
            <div class="section-title">Sentence Examples with Context</div>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>S/N</th>
                            <th>Word</th>
                            <th>Meaning in Bengali</th>
                            <th>Example Sentence (English)</th>
                            <th>Example Sentence (Bengali)</th>
                        </tr>
                    </thead>
                    <tbody>
        """
        
        for i, sentence_item in enumerate(sentence_data, 1):
            if isinstance(sentence_item, dict):
                word = sentence_item.get('word', '')
                meaning_bn = sentence_item.get('meaning_bn', '')
                example_en = sentence_item.get('example_en', '')
                example_bn = sentence_item.get('example_bn', '')
                
                html_content += f"""
                        <tr>
                            <td>{i}</td>
                            <td><strong>{word}</strong></td>
                            <td class="bengali-text">{meaning_bn}</td>
                            <td class="sentence-example sentence-example-en">{example_en}</td>
                            <td class="bengali-text sentence-example sentence-example-bn">{example_bn}</td>
                        </tr>
                """
        
        html_content += """
                    </tbody>
                </table>
            </div>
        </div>
        """
    
    # Add translation section if message exists
    if message:
        html_content += f"""
        <div class="section translation-section">
            <div class="section-title">English-Bengali Phrase by Phrase Translation</div>
            <div class="translation-content">
                <div class="english-text">{message}</div>
            </div>
        </div>
        """
    
    html_content += """
        <div class="footer">
            Generated by EnglishKaku  AI powered Workflow
        </div>
    </body>
    </html>
    """
    
    return html_content

@app.route('/convert-to-pdf', methods=['POST'])
def convert_to_pdf():
    """Convert JSON content to PDF and return as response"""
    try:
        # Get JSON data from request
        if not request.is_json:
            return jsonify({'error': 'Content-Type must be application/json'}), 400
        
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        # Convert JSON to HTML
        html_content = convert_json_to_html(data)
        
        # Create PDF using WeasyPrint
        font_config = FontConfiguration()
        
        # Create HTML object
        html_doc = HTML(string=html_content)
        
        # Generate PDF with landscape orientation
        pdf_bytes = html_doc.write_pdf(
            stylesheets=[],
            font_config=font_config
        )
        
        # Return PDF as response
        response = Response(
            pdf_bytes,
            mimetype='application/pdf',
            headers={
                'Content-Disposition': 'attachment; filename=english_learning_notes.pdf',
                'Content-Length': len(pdf_bytes)
            }
        )
        
        return response
        
    except Exception as e:
        return jsonify({'error': f'Error generating PDF: {str(e)}'}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'message': 'API is running'})

@app.route('/', methods=['GET'])
def home():
    """Home endpoint with usage instructions"""
    return jsonify({
        'message': 'AI Powered English Learning Notes PDF Converter API',
        'usage': {
            'endpoint': '/convert-to-pdf',
            'method': 'POST',
            'content_type': 'application/json',
            'body_format': 'JSON with title, time, message, and output fields'
        },
        'example': {
            'title': 'News Title',
            'time': '2025-08-29T01:57:50.782-04:00',
            'message': {
                'content': 'News content...',
                'title': 'News Title',
                'time': '2025-08-29T01:57:50.782-04:00',
                'sentence': '[{"word":"example","meaning_bn":"উদাহরণ","example_en":"This is an example sentence.","example_bn":"এটি একটি উদাহরণ বাক্য।"}]'
            },
            'output': [
                {
                    'english': 'word',
                    'bengali': 'শব্দ',
                    'synonyms': ['synonym1', 'synonym2'],
                    'antonyms': ['antonym1', 'antonym2']
                }
            ]
        }
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)