<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 700">
  
  <rect width="1000" height="700" fill="#f5f5f5"/>
  
  <!-- Title -->
  <text x="500" y="40" font-family="Arial" font-size="24" font-weight="bold" text-anchor="middle" fill="#333">Fintech Microservices Architecture</text>
  
  <!-- Kubernetes Cluster Border -->
  <rect x="50" y="70" width="900" height="580" rx="10" ry="10" fill="#E7F3FE" stroke="#1565C0" stroke-width="2" stroke-dasharray="5,5"/>
  <text x="130" y="90" font-family="Arial" font-size="16" font-weight="bold" fill="#1565C0">Kubernetes Cluster</text>
  
  <!-- Namespaces -->
  <rect x="70" y="100" width="860" height="530" rx="8" ry="8" fill="#F0F7FF" stroke="#3F51B5" stroke-width="1" stroke-dasharray="3,3"/>
  <text x="180" y="120" font-family="Arial" font-size="14" font-weight="bold" fill="#3F51B5">fintech-app Namespace</text>
  
  <!-- APISIX Gateway -->
  <rect x="100" y="140" width="800" height="80" rx="5" ry="5" fill="#FFF" stroke="#FF9800" stroke-width="2"/>
  <text x="500" y="170" font-family="Arial" font-size="16" font-weight="bold" text-anchor="middle" fill="#FF9800">APISIX API Gateway</text>
  <text x="500" y="195" font-family="Arial" font-size="12" text-anchor="middle" fill="#666">Routes traffic to microservices, enforces authentication</text>
  
  <!-- OPA -->
  <rect x="100" y="240" width="200" height="80" rx="5" ry="5" fill="#FFF" stroke="#9C27B0" stroke-width="2"/>
  <text x="200" y="270" font-family="Arial" font-size="16" font-weight="bold" text-anchor="middle" fill="#9C27B0">Open Policy Agent</text>
  <text x="200" y="295" font-family="Arial" font-size="12" text-anchor="middle" fill="#666">Policy enforcement, access control</text>
  
  <!-- Microservices -->
  <rect x="330" y="240" width="200" height="80" rx="5" ry="5" fill="#FFF" stroke="#2196F3" stroke-width="2"/>
  <text x="430" y="270" font-family="Arial" font-size="16" font-weight="bold" text-anchor="middle" fill="#2196F3">User Service</text>
  <text x="430" y="295" font-family="Arial" font-size="12" text-anchor="middle" fill="#666">Account management, balances</text>
  
  <rect x="560" y="240" width="200" height="80" rx="5" ry="5" fill="#FFF" stroke="#2196F3" stroke-width="2"/>
  <text x="660" y="270" font-family="Arial" font-size="16" font-weight="bold" text-anchor="middle" fill="#2196F3">Transaction Service</text>
  <text x="660" y="295" font-family="Arial" font-size="12" text-anchor="middle" fill="#666">Financial transactions</text>
  
  <!-- YugabyteDB -->
  <rect x="330" y="390" width="430" height="100" rx="5" ry="5" fill="#FFF" stroke="#4CAF50" stroke-width="2"/>
  <text x="545" y="425" font-family="Arial" font-size="16" font-weight="bold" text-anchor="middle" fill="#4CAF50">YugabyteDB (StatefulSet)</text>
  <text x="545" y="450" font-family="Arial" font-size="12" text-anchor="middle" fill="#666">Distributed SQL database for data persistence</text>
  <text x="545" y="470" font-family="Arial" font-size="12" text-anchor="middle" fill="#666">Users and Transactions tables</text>
  
  <!-- KEDA -->
  <rect x="100" y="390" width="200" height="100" rx="5" ry="5" fill="#FFF" stroke="#F44336" stroke-width="2"/>
  <text x="200" y="425" font-family="Arial" font-size="16" font-weight="bold" text-anchor="middle" fill="#F44336">KEDA</text>
  <text x="200" y="450" font-family="Arial" font-size="12" text-anchor="middle" fill="#666">Autoscaling based on HTTP metrics</text>
  <text x="200" y="470" font-family="Arial" font-size="12" text-anchor="middle" fill="#666">Scales pods automatically</text>
  
  <!-- Config & Secrets -->
  <rect x="330" y="520" width="200" height="70" rx="5" ry="5" fill="#FFF" stroke="#607D8B" stroke-width="2"/>
  <text x="430" y="550" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#607D8B">ConfigMaps</text>
  <text x="430" y="570" font-family="Arial" font-size="12" text-anchor="middle" fill="#666">Application configuration</text>
  
  <rect x="560" y="520" width="200" height="70" rx="5" ry="5" fill="#FFF" stroke="#607D8B" stroke-width="2"/>
  <text x="660" y="550" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#607D8B">Secrets</text>
  <text x="660" y="570" font-family="Arial" font-size="12" text-anchor="middle" fill="#666">Database credentials</text>
  
  <!-- Client -->
  <rect x="400" y="50" width="200" height="40" rx="20" ry="20" fill="#FFF" stroke="#333" stroke-width="2"/>
  <text x="500" y="75" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#333">Client Applications</text>

  <!-- Helm -->
  <rect x="780" y="520" width="120" height="70" rx="5" ry="5" fill="#FFF" stroke="#2196F3" stroke-width="2"/>
  <text x="840" y="550" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2196F3">Helm Chart</text>
  <text x="840" y="570" font-family="Arial" font-size="12" text-anchor="middle" fill="#666">Deployment manager</text>
  
  <!-- Lines connecting components with animations -->
  <!-- Client to API Gateway -->
  <line x1="500" y1="90" x2="500" y2="140" stroke="#333" stroke-width="2"/>
  <line x1="500" y1="90" x2="500" y2="140" stroke="#333" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="1" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  <polygon points="500,140 495,130 505,130" fill="#333"/>
  
  <!-- API Gateway to Services -->
  <line x1="420" y1="220" x2="430" y2="240" stroke="#FF9800" stroke-width="2"/>
  <line x1="420" y1="220" x2="430" y2="240" stroke="#FF9800" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  
  
  <line x1="580" y1="220" x2="570" y2="240" stroke="#FF9800" stroke-width="2"/>
  <line x1="580" y1="220" x2="570" y2="240" stroke="#FF9800" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>

  <!-- OPA to Services -->
  <line x1="300" y1="280" x2="330" y2="280" stroke="#9C27B0" stroke-width="2"/>
  <line x1="300" y1="280" x2="330" y2="280" stroke="#9C27B0" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  <polygon points="330,280 320,275 320,285" fill="#9C27B0"/>
  
  <!-- Services to DB -->
  <line x1="430" y1="320" x2="430" y2="390" stroke="#2196F3" stroke-width="2"/>
  <line x1="430" y1="320" x2="430" y2="390" stroke="#2196F3" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  <polygon points="430,390 425,380 435,380" fill="#2196F3"/>
  
  <line x1="660" y1="320" x2="660" y2="390" stroke="#2196F3" stroke-width="2"/>
  <line x1="660" y1="320" x2="660" y2="390" stroke="#2196F3" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  <polygon points="660,390 655,380 665,380" fill="#2196F3"/>
  
  <!-- Services interconnection -->
  <path d="M 530 280 Q 545 260 560 280" stroke="#2196F3" stroke-width="2" fill="none"/>
  <path d="M 530 280 Q 545 260 560 280" stroke="#2196F3" stroke-width="2" fill="none" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </path>
  
  <!-- KEDA to Services -->
  <line x1="200" y1="390" x2="200" y2="310" stroke="#F44336" stroke-width="2" stroke-dasharray="5,3"/>
  <line x1="200" y1="390" x2="200" y2="310" stroke="#F44336" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  
  <line x1="200" y1="310" x2="300" y2="310" stroke="#F44336" stroke-width="2" stroke-dasharray="5,3"/>
  <line x1="200" y1="310" x2="300" y2="310" stroke="#F44336" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="15" to="0" dur="0.5s" repeatCount="indefinite"/>
  </line>
  
  <line x1="300" y1="310" x2="430" y2="310" stroke="#F44336" stroke-width="2" stroke-dasharray="5,3"/>
  <line x1="300" y1="310" x2="430" y2="310" stroke="#F44336" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="15" to="0" dur="0.5s" repeatCount="indefinite"/>
  </line>
  <polygon points="430,310 420,305 420,315" fill="#F44336"/>
  
  <line x1="300" y1="310" x2="300" y2="340" stroke="#F44336" stroke-width="2" stroke-dasharray="5,3"/>
  <line x1="300" y1="310" x2="300" y2="340" stroke="#F44336" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  
  <line x1="300" y1="340" x2="660" y2="340" stroke="#F44336" stroke-width="2" stroke-dasharray="5,3"/>
  <line x1="300" y1="340" x2="660" y2="340" stroke="#F44336" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  <polygon points="660,340 650,335 650,345" fill="#F44336"/>
  
  <!-- ConfigMap/Secrets to Services -->
  <line x1="430" y1="520" x2="430" y2="500" stroke="#607D8B" stroke-width="2" stroke-dasharray="4,2"/>
  <line x1="430" y1="520" x2="430" y2="500" stroke="#607D8B" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  
  <line x1="430" y1="500" x2="350" y2="500" stroke="#607D8B" stroke-width="2" stroke-dasharray="4,2"/>
  <line x1="430" y1="500" x2="350" y2="500" stroke="#607D8B" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  
  <line x1="350" y1="500" x2="350" y2="320" stroke="#607D8B" stroke-width="2" stroke-dasharray="4,2"/>
  <line x1="350" y1="500" x2="350" y2="320" stroke="#607D8B" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  <polygon points="350,320 345,330 355,330" fill="#607D8B"/>
  
  <line x1="660" y1="520" x2="660" y2="500" stroke="#607D8B" stroke-width="2" stroke-dasharray="4,2"/>
  <line x1="660" y1="520" x2="660" y2="500" stroke="#607D8B" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="15" to="1" dur="0.5s" repeatCount="indefinite"/>
  </line>
  
  <line x1="660" y1="500" x2="740" y2="500" stroke="#607D8B" stroke-width="2" stroke-dasharray="4,2"/>
  <line x1="660" y1="500" x2="740" y2="500" stroke="#607D8B" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="15" to="1" dur="0.5s" repeatCount="indefinite"/>
  </line>
  
  <line x1="740" y1="500" x2="740" y2="320" stroke="#607D8B" stroke-width="2" stroke-dasharray="4,2"/>
  <line x1="740" y1="500" x2="740" y2="320" stroke="#607D8B" stroke-width="2" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </line>
  <polygon points="740,320 735,330 745,330" fill="#607D8B"/>
  
  <!-- Helm connections -->
  <path d="M 840 520 Q 860 470 880 400 Q 900 300 880 200 Q 860 120 820 140" stroke="#2196F3" stroke-width="1" stroke-dasharray="5,5" fill="none"/>
  <path d="M 840 520 Q 860 470 880 400 Q 900 300 880 200 Q 860 120 820 140" stroke="#2196F3" stroke-width="1" fill="none" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </path>
  
  <path d="M 840 520 Q 820 460 780 400 Q 750 350 720 320" stroke="#2196F3" stroke-width="1" stroke-dasharray="5,5" fill="none"/>
  <path d="M 840 520 Q 820 460 780 400 Q 750 350 720 320" stroke="#2196F3" stroke-width="1" fill="none" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </path>
  
  <path d="M 840 520 Q 800 480 760 450 Q 700 420 630 390" stroke="#2196F3" stroke-width="1" stroke-dasharray="5,5" fill="none"/>
  <path d="M 840 520 Q 800 480 760 450 Q 700 420 630 390" stroke="#2196F3" stroke-width="1" fill="none" stroke-dasharray="10 5" opacity="0.8">
    <animate attributeName="stroke-dashoffset" from="0" to="15" dur="0.5s" repeatCount="indefinite"/>
  </path>
  
  <!-- Legend -->
  <rect x="100" y="610" width="800" height="40" rx="5" ry="5" fill="#FFF" stroke="#333" stroke-width="1"/>
  <circle cx="130" cy="625" r="6" fill="#FF9800"/>
  <text x="150" y="630" font-family="Arial" font-size="12" fill="#333">API Gateway</text>
  
  <circle cx="250" cy="625" r="6" fill="#9C27B0"/>
  <text x="270" y="630" font-family="Arial" font-size="12" fill="#333">Security/Policy</text>
  
  <circle cx="370" cy="625" r="6" fill="#2196F3"/>
  <text x="390" y="630" font-family="Arial" font-size="12" fill="#333">Microservices</text>
  
  <circle cx="490" cy="625" r="6" fill="#4CAF50"/>
  <text x="510" y="630" font-family="Arial" font-size="12" fill="#333">Data Storage</text>
  
  <circle cx="590" cy="625" r="6" fill="#F44336"/>
  <text x="610" y="630" font-family="Arial" font-size="12" fill="#333">Autoscaling</text>
  
  <circle cx="690" cy="625" r="6" fill="#607D8B"/>
  <text x="710" y="630" font-family="Arial" font-size="12" fill="#333">Configuration</text>
  
  <line x1="790" y1="625" x2="820" y2="625" stroke="#333" stroke-width="2" stroke-dasharray="5,3"/>
  <text x="830" y="630" font-family="Arial" font-size="12" fill="#333">Flow</text>
</svg>