-- Format je Zeile: <Stufe 1-6> <DE-Namen/Alias> = <EN-Namen/Alias>
-- Ohne " = " gilt der Name für beide Sprachen. Erster Name = Anzeige.
-- Stufen: 1 Plankton, 2 Zu clever, 3 Schwarm, 4 Selten, 5 Tiefsee, 6 Die Nische (genau 1 pro Prompt)
return {
{ id = "geo_capital_eu", de = "Nenne eine Hauptstadt in Europa", en = "Name a capital city in Europe", a = [[
1 Berlin
1 Paris
1 London
1 Rom = Rome
1 Madrid
1 Wien = Vienna
2 Vaduz
2 Vatikanstadt/Vatikan = Vatican City/Vatican
2 Reykjavik
3 Amsterdam
3 Brüssel = Brussels
3 Prag = Prague
3 Warschau = Warsaw
3 Lissabon = Lisbon
3 Athen = Athens
3 Oslo
3 Stockholm
3 Kopenhagen = Copenhagen
3 Bern
3 Dublin
3 Budapest
3 Helsinki
4 Bratislava/Pressburg
4 Ljubljana
4 Zagreb
4 Belgrad = Belgrade
4 Bukarest = Bucharest
4 Sofia
4 Riga
4 Tallinn
4 Vilnius/Wilna
4 Kiew/Kyjiw = Kyiv/Kiev
4 Minsk
4 Luxemburg = Luxembourg
4 Monaco
4 Valletta
4 Andorra la Vella
4 San Marino
5 Tirana
5 Skopje
5 Sarajevo
5 Chisinau/Kischinau = Chisinau
5 Nikosia = Nicosia
5 Pristina
6 Podgorica
]] },
{ id = "geo_africa", de = "Nenne ein Land in Afrika", en = "Name a country in Africa", a = [[
1 Ägypten = Egypt
1 Südafrika = South Africa
1 Nigeria
1 Kenia = Kenya
1 Marokko = Morocco
2 Madagaskar = Madagascar
3 Ghana
3 Äthiopien = Ethiopia
3 Tansania = Tanzania
3 Algerien = Algeria
3 Tunesien = Tunisia
3 Kamerun = Cameroon
3 Senegal
3 Uganda
3 Kongo/Demokratische Republik Kongo = Congo/DR Congo
3 Somalia
3 Sudan
3 Libyen = Libya
3 Namibia
3 Simbabwe = Zimbabwe
4 Angola
4 Mali
4 Ruanda = Rwanda
4 Botswana
4 Sambia = Zambia
4 Mosambik = Mozambique
4 Niger
4 Tschad = Chad
4 Elfenbeinküste = Ivory Coast/Cote d'Ivoire
4 Gabun = Gabon
4 Malawi
4 Burkina Faso
4 Benin
4 Togo
4 Mauretanien = Mauritania
4 Eritrea
4 Liberia
4 Sierra Leone
4 Guinea
4 Südsudan = South Sudan
5 Dschibuti = Djibouti
5 Lesotho
5 Eswatini/Swasiland = Eswatini/Swaziland
5 Komoren = Comoros
5 Kap Verde/Cabo Verde = Cape Verde/Cabo Verde
5 Seychellen = Seychelles
5 Mauritius
5 Gambia
5 Guinea-Bissau
5 Äquatorialguinea = Equatorial Guinea
5 Burundi
5 Zentralafrikanische Republik = Central African Republic
6 São Tomé und Príncipe/Sao Tome = São Tomé and Príncipe/Sao Tome
]] },
{ id = "geo_river", de = "Nenne einen Fluss", en = "Name a river", a = [[
1 Rhein = Rhine
1 Nil = Nile
1 Donau = Danube
1 Amazonas = Amazon
1 Mississippi
1 Elbe
2 Jangtse/Jangtsekiang = Yangtze
3 Main
3 Mosel = Moselle
3 Weser
3 Oder
3 Seine
3 Themse = Thames
3 Wolga = Volga
3 Ganges
3 Po
3 Tiber
3 Ems
3 Spree
3 Neckar
3 Isar
3 Inn
3 Colorado
3 Missouri
4 Loire
4 Rhone/Rhône
4 Ebro
4 Tajo = Tagus
4 Weichsel = Vistula
4 Dnepr/Dnipro = Dnieper/Dnipro
4 Mekong
4 Indus
4 Euphrat = Euphrates
4 Tigris
4 Kongo = Congo
4 Sambesi = Zambezi
4 Saale
4 Lahn
4 Havel
4 Ruhr
4 Lech
4 Jordan
4 Hudson
4 Rio Grande
5 Lena
5 Jenissei = Yenisei
5 Ob
5 Amur
5 Orinoco
5 Paraná/Parana
5 Murray
5 Okavango
5 Irrawaddy/Irawadi
5 Brahmaputra
5 Huang He/Gelber Fluss = Yellow River/Huang He
5 Mackenzie
5 Yukon
5 Wupper
5 Nahe
6 Limpopo
]] },
{ id = "geo_southamerica", de = "Nenne ein Land in Südamerika", en = "Name a country in South America", a = [[
1 Brasilien = Brazil
1 Argentinien = Argentina
3 Kolumbien = Colombia
3 Chile
3 Peru
3 Venezuela
4 Bolivien = Bolivia
4 Ecuador
4 Uruguay
4 Paraguay
5 Guyana
6 Suriname
]] },
{ id = "geo_island", de = "Nenne eine Insel", en = "Name an island", a = [[
1 Mallorca = Mallorca/Majorca
1 Hawaii
1 Sizilien = Sicily
1 Grönland = Greenland
1 Madagaskar = Madagascar
2 Osterinsel = Easter Island
3 Rügen
3 Sylt
3 Kreta = Crete
3 Sardinien = Sardinia
3 Korsika = Corsica
3 Bali
3 Ibiza
3 Teneriffa = Tenerife
3 Zypern = Cyprus
3 Island = Iceland
3 Irland = Ireland
3 Tasmanien = Tasmania
3 Borneo
3 Sri Lanka
3 Kuba = Cuba
3 Jamaika = Jamaica
3 Malta
3 Gran Canaria
3 Rhodos = Rhodes
3 Helgoland = Heligoland
3 Usedom
3 Fehmarn
4 Sumatra
4 Java
4 Neuguinea = New Guinea
4 Honshu
4 Spitzbergen = Svalbard/Spitsbergen
4 Färöer = Faroe Islands/Faroes
4 Gotland
4 Bornholm
4 Elba
4 Capri
4 Santorini
4 Lanzarote
4 Fuerteventura
4 La Palma
4 Madeira
4 Azoren = Azores
4 Mauritius
4 Malediven = Maldives
4 Föhr
4 Amrum
4 Norderney
4 Borkum
5 Sachalin = Sakhalin
5 Baffininsel = Baffin Island
5 Ellesmere
5 Hokkaido
5 Kyushu
5 Sokotra = Socotra
5 Pitcairn
5 St. Helena/Sankt Helena = Saint Helena/St Helena
5 Spiekeroog
5 Juist
5 Langeoog
5 Pellworm
5 Hiddensee
5 Lampedusa
5 La Gomera/Gomera
5 El Hierro
6 Tristan da Cunha
]] },
}
