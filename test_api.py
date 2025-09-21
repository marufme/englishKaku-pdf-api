import requests
import json

# Test data
test_data = [
  {
    "message": {
      "content": "On Friday, August 29, 2025 (শুক্রবার, ২৯ আগস্ট, ২০২৫), an intense confrontation (একটি তীব্র সংঘর্ষ) erupted (বিস্ফোরিত হয়েছিল) between students of the Bangladesh University of Engineering and Technology—BUET (বাংলাদেশ প্রকৌশল বিশ্ববিদ্যালয়ের শিক্ষার্থীরা) and law enforcement (আইনশৃঙ্খলা রক্ষাকারী বাহিনী), as the former (প্রথমপক্ষ) endeavored (চেষ্টারত ছিল) to proceed towards the Chief Adviser's (CA) official residence, Jamuna (প্রধান উপদেষ্টার সরকারি বাসভবন, যমুনা), in order to articulate (উচ্চারণে) and champion (অগ্রগতিতে) their demands (তাদের দাবিসমূহ) with unyielding resolve (অদম্য দৃঢ়তায়)।\n\nThe altercation (বিরোধ) escalated (তীব্রতর হয়) around 2 pm (দুপুর ২টার দিকে) near the National Press Club (জাতীয় প্রেস ক্লাবের আশেপাশে), as students, in the throes of their "Long March to Dhaka" programme (তাদের 'ঢাকামুখী দীর্ঘমার্চ' কর্মসূচির অন্তর্গত), encountered a formidable police barricade (একটি দৃঢ় পুলিশ ব্যারিকেডের সম্মুখীন হয়েছিল) designed to thwart (প্রতিহত করতে) any advancement (অগ্রগতি) towards the strategic government enclave (গুরুত্বপূর্ণ সরকারি এলাকা)।\n\nEarlier that day (সে দিনের শুরুতেই), circa 11:30 am (প্রায় সকাল সাড়ে ১১টার দিকে), a massive procession (একটি ব্যাপক মিছিল) originated (সূচনা হয়) from BUET campus (বুয়েট ক্যাম্পাস থেকে) and converged (একত্রিত হয়) at the main thoroughfare of Shahbagh (প্রধান শাহবাগ সড়কে), precipitating (আপৎকালীনভাবে সৃষ্টি করেছিল) a paralyzing traffic gridlock (স্থবির যানজট) across adjacent roads (পার্শ্ববর্তী সড়কগুলোতেও)।\n\nIn anticipation of mass mobilization (বৃহৎ সক্রিয়তার আশাঙ্কায়), the government (সরকার) deployed augmented police contingents (আরও অধিক সংখ্যক পুলিশ) throughout the Secretariat and National Press Club precincts (সচিবালয় ও প্রেস ক্লাব এলাকা জুড়ে), striving to preclude (প্রতিরোধ করতে চেষ্টা করেছিল) possible civil unrest (সম্ভাব্য গণঅসন্তোষ)।\n\nThe vociferous assemblage (উচ্চগ্রামী জমায়েত) of engineering students (প্রকৌশল শিক্ষার্থীরা), not solely limited to BUET but inclusive of other premier institutions—KUET, RUET, CUET, SUST, MIST, AUST, BUTEX (কুয়েট, রুয়েট, চুয়েট, সাস্ট, মিস্ট, এএউএসটি, বুটেক্সসহ)—alongside faculty members (শিক্ষকবৃন্দ), coalesced (একত্রিত হয়েছিল) to propound (প্রয়োগ করেছিল) three pivotal demands (তিনটি মুখ্য দাবি)।\n\nTheir foremost assertion (তাদের প্রধান দাবি) stipulates (উল্লেখ করে) that entry examinations (ভর্তি পরীক্ষা) be rendered obligatory (বাধ্যতামূলক) for aspirants (প্রত্যাশীরা) of ninth grade (নবম গ্রেড) engineering roles (প্রকৌশল সংক্রান্ত পদসমূহ), such as Assistant Engineer (সহকারী প্রকৌশলী), restricting eligibility (যা শুধুমাত্র যোগ্যতা নির্ধারণ করে) to holders of a bona fide BSc degree (মূল বি.এস.সি ডিগ্রিধারীদের জন্য)।\n\nConcurrently (একইসাথে), they vehemently oppose (তীব্রভাবে আপত্তি জানায়) anomalous promotional mechanisms (অনিয়মিত পদোন্নতি পদ্ধতির বিরুদ্ধে), particularly via quotas or equivalent designations (কোটা বা সমতুল্য পদবী সৃষ্টির মাধ্যমে), which, they allege (তাদের অভিযোগ অনুযায়ী), undermine meritocratic principles (মেধাভিত্তিক মূল্যবোধকে দুর্বল করে)।\n\nSimultaneously (সমান্তরালে), the student coalition (ছাত্র ঐক্য) advocates (সমর্থন করে) that recruitment exams for the 10th grade (দশম গ্রেডের) or Sub-Assistant Engineer posts (উপ-সহকারী প্রকৌশলী পদসমূহ) must be accessible (সহজগম্য হওয়া উচিত) to both diploma and BSc graduates (ডিপ্লোমা ও বি.এস.সি উভয় ডিগ্রিধারীর জন্য)।\n\nFurthermore (পরিষ্কারভাবে), protesters demand stringent legal actions (কঠোর আইনি ব্যবস্থা) against individuals illicitly appropriating (অবৈধভাবে ব্যবহারকারী) the title "engineer" (ইঞ্জিনিয়ার পদবী) sans accredited BSc credentials (স্বীকৃত বি.এস.সি ডিগ্রি ছাড়া)। They also urge that all non-accredited engineering programmes (স্বীকৃতিহীন প্রকৌশল প্রোগ্রামসমূহ) undergo rigorous scrutiny (কঠিন পরীক্ষা-নিরীক্ষা) and standardization via IEB-BTEB accreditation (আইইবি-বিটিইবি স্বীকৃতির মাধ্যমে) following nationally ratified protocol (জাতীয়ভাবে অনুমোদিত পদ্ধতিতে)।\n\nHowever (তবে), amidst the tense standoff (চরম উত্তেজনার আবহে), it must be noted (জানানো প্রয়োজন) that the Dhaka Metropolitan Police (ঢাকা মেট্রোপলিটন পুলিশ) had proscribed (নিষিদ্ধ করেছিল) all assemblies (সমস্ত জমায়েত), processions (মিছিল), and rallies (সমাবেশ) within the periphery of the Secretariat and Jamuna (সচিবালয় ও যমুনার আশেপাশে), amplifying both the precariousness (অনিশ্চয়তা) and volatility (অস্থিরতা) of the situation.\n\nIn this crucible of tension (উত্তেজনার এই চূড়ান্ত পর্যায়ে), the clash (সংঘর্ষ) between students and police (ছাত্র-শিক্ষক ও পুলিশের মাঝে) epitomized (প্রতিনিধিত্ব করেছিল) a larger societal debate (একটি বৃহত্তর সামাজিক বিতর্ক) regarding professional qualification, meritocracy (প্রকৃত মেধার মূল্যায়ন), and bureaucratic reform (প্রশাসনিক সংস্কার) in Bangladesh's engineering sector (বাংলাদেশের প্রকৌশল ক্ষেত্রে)।\n\nThe denouement (পরিণতি) of this agitation (এই আন্দোলনের) remains uncertain (অজানা থেকে যায়), yet the resonance of their protest (তাদের প্রতিবাদের প্রতিধ্বনি) is likely to reverberate (প্রতিধ্বনিত হতে পারে) through policy corridors (নীতিনির্ধারণী অঙ্গনজুড়ে) in the days ahead (আসন্ন দিনগুলোতে)।"
    },
    "output": [
      {
        "english": "confrontation",
        "bengali": "একটি তীব্র সংঘর্ষ",
        "synonyms": [
          "conflict",
          "clash"
        ],
        "antonyms": [
          "agreement",
          "peace"
        ]
      },
      {
        "english": "endeavor",
        "bengali": "চেষ্টারত ছিল",
        "synonyms": [
          "attempt",
          "effort"
        ],
        "antonyms": [
          "abandon",
          "neglect"
        ]
      },
      {
        "english": "articulate",
        "bengali": "উচ্চারণে",
        "synonyms": [
          "express",
          "enunciate"
        ],
        "antonyms": [
          "mumble",
          "confuse"
        ]
      },
      {
        "english": "thwart",
        "bengali": "প্রতিহত করতে",
        "synonyms": [
          "prevent",
          "obstruct"
        ],
        "antonyms": [
          "assist",
          "facilitate"
        ]
      },
      {
        "english": "augment",
        "bengali": "আরও অধিক সংখ্যক",
        "synonyms": [
          "increase",
          "expand"
        ],
        "antonyms": [
          "decrease",
          "reduce"
        ]
      },
      {
        "english": "reiterate",
        "bengali": "",
        "synonyms": [
          "repeat",
          "restate"
        ],
        "antonyms": [
          "retract",
          "withdraw"
        ]
      },
      {
        "english": "preclude",
        "bengali": "প্রতিরোধ করতে চেষ্টা করেছিল",
        "synonyms": [
          "foreclose",
          "prevent"
        ],
        "antonyms": [
          "allow",
          "permit"
        ]
      },
      {
        "english": "advocate",
        "bengali": "সমর্থন করে",
        "synonyms": [
          "support",
          "promote"
        ],
        "antonyms": [
          "oppose",
          "criticize"
        ]
      },
      {
        "english": "stringent",
        "bengali": "কঠোর",
        "synonyms": [
          "strict",
          "rigorous"
        ],
        "antonyms": [
          "lenient",
          "mild"
        ]
      },
      {
        "english": "illicit",
        "bengali": "অবৈধভাবে",
        "synonyms": [
          "illegal",
          "unlawful"
        ],
        "antonyms": [
          "legal",
          "lawful"
        ]
      },
      {
        "english": "scrutiny",
        "bengali": "পরীক্ষা-নিরীক্ষা",
        "synonyms": [
          "examination",
          "inspection"
        ],
        "antonyms": [
          "neglect",
          "overlook"
        ]
      },
      {
        "english": "proscribe",
        "bengali": "নিষিদ্ধ করেছিল",
        "synonyms": [
          "ban",
          "forbid"
        ],
        "antonyms": [
          "allow",
          "permit"
        ]
      },
      {
        "english": "resonance",
        "bengali": "প্রতিধ্বনি",
        "synonyms": [
          "echo",
          "reverberation"
        ],
        "antonyms": [
          "silence",
          "dullness"
        ]
      },
      {
        "english": "uncertain",
        "bengali": "অজানা থেকে যায়",
        "synonyms": [
          "ambiguous",
          "unclear"
        ],
        "antonyms": [
          "certain",
          "definite"
        ]
      },
      {
        "english": "volatility",
        "bengali": "অস্থিরতা",
        "synonyms": [
          "instability",
          "unpredictability"
        ],
        "antonyms": [
          "stability",
          "steadiness"
        ]
      }
    ],
    "time": "2025-08-29T10:55:30.742-04:00",
    "title": "BUET students, police clash in pursuit and standoff near CA's residence"
  }
]

def test_api():
    """Test the API with the provided JSON data"""
    url = "http://localhost:5000/convert-to-pdf"
    
    try:
        # Send POST request to convert-to-pdf endpoint
        response = requests.post(url, json=test_data, headers={'Content-Type': 'application/json'})
        
        if response.status_code == 200:
            # Save the PDF
            with open('test_output.pdf', 'wb') as f:
                f.write(response.content)
            print("✅ PDF generated successfully! Saved as 'test_output.pdf'")
            print(f"📄 PDF size: {len(response.content)} bytes")
        else:
            print(f"❌ Error: {response.status_code}")
            print(f"Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection error: Make sure the Flask API is running on localhost:5000")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

if __name__ == "__main__":
    test_api()
