# XML-API
Package zur automatisierten Erstellung einer XML-API

## Was ist XML-API?

XML-API stellt eine Keimzelle für einen Codegenerator dar, der, basierend auf einer XML-Schema-Datei, automatisiert eine API in PL/SQL erstellt. »Keimzelle« insofern, als derzeit Restriktionen bezüglich der Art der Erstellung von XML Schema Dateien existieren.
Derzeit unterstützt XML-API die Analyse von »direkt« erstellten Strukturen, in denen Kindelemente direkt innerhalb ihres Elternelements definiert werden und nicht über die separate Definition mittels Complex Type.Zudem sind die Analysen des Datentyps auf das beschränkt, was im bisherigen Projekt erforderlich war.

## Arbeitsweise

Die XSD wird durch ein Stylesheet aufbereitet und erstellt eine XML_Datei, die alle definierten Elemente sowie ihren Pfad zum Wurzelelement enthält. Zudem wird analysiert, ob das Element optional oder mehrfach einfügbar ist und welchen Datentyp es enthalten soll (Diese Analyse umfasst lediglich soviel Information, das hieraus ein SQL-Datentyp abgeleitet werden kann, nicht aber Informationen über Patterns, Enumerations oder sonstigen Einschränkungen).
Die entstandene XML-Datei wird anschließend durch einen Codegenerator geschickt, der aus den Elternelementen Methoden ableitet, um die Kindelemente mit Daten zu versorgen und diese anschließend in ein Muster-XML einzufügen. Dieses Muster-XML ist so aufgebaut, dass es nach der Vervollständigung mit Daten gegen das Schema validiert. Optionale Elemente werden im Regelfall als leere Elemente eingefügt und im letzten Schritt aus der XML-Instanz entfernt. Elemente, die alternativ eingefügt werden, werden unterschiedlich behandelt: Handelt es sich um Blätter, werden alle optionalen Elemente eingefügt und die leeren letztlich entfernt. Knoten werden als Blätter eingefügt und, wenn sie verwendet werden sollen, durch ein XML-Template um ihre Kindelemente erweitert. Darin enthaltene, optionale Elemente werden wie üblich behandelt.

## Limitierungen

Die vorliegende Implementierung ist als projektbezogener Code auf eine konkrete Situation hin optimiert. Müssen komplexere XSD-Situationen bearbeitet werden, muss entweder die Analyselogik des XSLT verbessert und/oder zusätzlicher Code im Package eingefügt werden. Insofern stellt die Implementierung einen ersten Ansatz dar, kein ausgereiftes Werkzeug.
