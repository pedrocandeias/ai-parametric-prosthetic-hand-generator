# Dimensões do corpo da mão (palma) — série de crescimento

Bounding box (mm) do **corpo da mão** de cada modelo ativo, dimensionado por IA para quatro
idades. O "corpo da mão" é a **palma isolada**, que já inclui a **sela de encaixe do polegar**
(a estrutura solidária com a palma onde o polegar articula). **Não** conta o dedo polegar, os
quatro dedos, nem o gauntlet — peças impressas separadamente.

Apresentam-se três tabelas: o **valor nominal digital** (o modelo tal como sai do OpenSCAD) e
os valores **após impressão**, corrigidos pela **distorção natural de encolhimento
térmico** do material ao arrefecer, com **variação peça-a-peça** (cada peça encolhe um pouco
diferente).

## 1. Nominal — modelo digital

| Modelo | Perfil | X (mm) | Y (mm) | Z (mm) |
|---|---|--:|--:|--:|
| Flexy Beast | 8 anos | 97,385 | 80,103 | 37,123 |
| Flexy Beast | 15 anos | 117,144 | 96,355 | 44,655 |
| Flexy Beast | 28 anos | 134,081 | 110,286 | 51,112 |
| Flexy Beast | 70 anos | 125,612 | 103,321 | 47,884 |
| Paraglider Hand | 8 anos | 76,513 | 86,306 | 28,989 |
| Paraglider Hand | 15 anos | 94,730 | 106,855 | 35,892 |
| Paraglider Hand | 28 anos | 109,304 | 123,295 | 41,414 |
| Paraglider Hand | 70 anos | 102,017 | 115,075 | 38,653 |
| UnLimbited Phoenix | 8 anos | 82,165 | 91,964 | 30,553 |
| UnLimbited Phoenix | 15 anos | 88,177 | 98,693 | 32,789 |
| UnLimbited Phoenix | 28 anos | 90,181 | 100,936 | 33,534 |
| UnLimbited Phoenix | 70 anos | 84,169 | 94,207 | 31,298 |

## 2. Após impressão — PLA

| Modelo | Perfil | s aplicado | X (mm) | Y (mm) | Z (mm) |
|---|---|--:|--:|--:|--:|
| Flexy Beast | 8 anos | 0,29 % | 97,101 | 79,869 | 37,015 |
| Flexy Beast | 15 anos | 0,30 % | 116,798 | 96,071 | 44,524 |
| Flexy Beast | 28 anos | 0,29 % | 133,690 | 109,965 | 50,963 |
| Flexy Beast | 70 anos | 0,32 % | 125,214 | 102,994 | 47,732 |
| Paraglider Hand | 8 anos | 0,31 % | 76,277 | 86,040 | 28,900 |
| Paraglider Hand | 15 anos | 0,32 % | 94,431 | 106,517 | 35,778 |
| Paraglider Hand | 28 anos | 0,30 % | 108,972 | 122,920 | 41,288 |
| Paraglider Hand | 70 anos | 0,32 % | 101,690 | 114,707 | 38,529 |
| UnLimbited Phoenix | 8 anos | 0,27 % | 81,940 | 91,712 | 30,469 |
| UnLimbited Phoenix | 15 anos | 0,31 % | 87,908 | 98,391 | 32,688 |
| UnLimbited Phoenix | 28 anos | 0,30 % | 89,914 | 100,637 | 33,434 |
| UnLimbited Phoenix | 70 anos | 0,28 % | 83,929 | 93,939 | 31,209 |

## 3. Após impressão — PETG

| Modelo | Perfil | s aplicado | X (mm) | Y (mm) | Z (mm) |
|---|---|--:|--:|--:|--:|
| Flexy Beast | 8 anos | 0,37 % | 97,024 | 79,806 | 36,986 |
| Flexy Beast | 15 anos | 0,39 % | 116,688 | 95,980 | 44,481 |
| Flexy Beast | 28 anos | 0,39 % | 133,554 | 109,853 | 50,911 |
| Flexy Beast | 70 anos | 0,41 % | 125,091 | 102,892 | 47,685 |
| Paraglider Hand | 8 anos | 0,40 % | 76,204 | 85,957 | 28,872 |
| Paraglider Hand | 15 anos | 0,37 % | 94,377 | 106,457 | 35,758 |
| Paraglider Hand | 28 anos | 0,42 % | 108,841 | 122,772 | 41,238 |
| Paraglider Hand | 70 anos | 0,42 % | 101,593 | 114,597 | 38,492 |
| UnLimbited Phoenix | 8 anos | 0,40 % | 81,839 | 91,599 | 30,432 |
| UnLimbited Phoenix | 15 anos | 0,42 % | 87,807 | 98,279 | 32,651 |
| UnLimbited Phoenix | 28 anos | 0,39 % | 89,832 | 100,545 | 33,404 |
| UnLimbited Phoenix | 70 anos | 0,40 % | 83,831 | 93,829 | 31,173 |

## Eixos

- **X** — largura (lado a lado, mindinho→polegar), inclui a sela do polegar (+X).
- **Y** — comprimento (punho→nós dos dedos).
- **Z** — espessura (palmar→dorsal).

