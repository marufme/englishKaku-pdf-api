#!/usr/bin/env python3
"""
Test script for the simplified English-Bengali Dictionary API
"""

import requests
import json

def test_api():
    """Test the API endpoints"""
    base_url = "http://localhost:5000"
    
    print("Testing English-Bengali Dictionary API...")
    print("=" * 50)
    
    # Test 1: Health check
    print("\n1. Testing health check...")
    try:
        response = requests.get(f"{base_url}/health")
        if response.status_code == 200:
            print("✅ Health check passed")
            print(f"   Response: {response.json()}")
        else:
            print(f"❌ Health check failed: {response.status_code}")
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to API. Make sure it's running on port 5000")
        return
    
    # Test 2: Home endpoint
    print("\n2. Testing home endpoint...")
    try:
        response = requests.get(f"{base_url}/")
        if response.status_code == 200:
            print("✅ Home endpoint passed")
            print(f"   Message: {response.json().get('message', 'N/A')}")
        else:
            print(f"❌ Home endpoint failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Home endpoint error: {e}")
    
    # Test 3: Convert to HTML
    print("\n3. Testing convert-to-html endpoint...")
    
    test_data = {
        "data": [
            {
                "english": "proscription",
                "bengali": "নিষেধাজ্ঞা",
                "synonyms": ["ban", "prohibition", "interdiction"],
                "antonyms": ["authorization", "permission", "approval"]
            },
            {
                "english": "serendipity",
                "bengali": "সৌভাগ্য",
                "synonyms": ["fortune", "luck", "chance"],
                "antonyms": ["misfortune", "bad luck", "unluckiness"]
            }
        ],
        "message": "Sample English-Bengali dictionary entries for testing purposes."
    }
    
    try:
        response = requests.post(
            f"{base_url}/convert-to-html",
            json=test_data,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 200:
            print("✅ Convert to HTML passed")
            print(f"   Content-Type: {response.headers.get('Content-Type', 'N/A')}")
            print(f"   Content-Length: {len(response.content)} bytes")
            
            # Save the HTML file for inspection
            with open('test_output.html', 'w', encoding='utf-8') as f:
                f.write(response.text)
            print("   HTML saved to: test_output.html")
            print("   You can open this file in your browser and use Print to PDF")
            
        else:
            print(f"❌ Convert to HTML failed: {response.status_code}")
            print(f"   Error: {response.text}")
            
    except Exception as e:
        print(f"❌ Convert to HTML error: {e}")
    
    print("\n" + "=" * 50)
    print("Testing completed!")
    print("\nTo test manually:")
    print(f"1. Open your browser and go to: {base_url}")
    print("2. Use the test_output.html file to see the generated HTML")
    print("3. Use your browser's Print function to save as PDF")

if __name__ == '__main__':
    test_api()
