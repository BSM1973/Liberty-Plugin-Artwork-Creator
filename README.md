# Liberty Plugin Artwork Creator

Application macOS indépendante pour capturer les interfaces graphiques de plugins AU/VST3 et créer des miniatures PNG pour Liberty DAW.

## Télécharger sans Xcode

Ouvrir **Actions → Build macOS app → dernière exécution réussie**, puis télécharger l'artefact **Liberty-Plugin-Artwork-Creator-macOS-arm64**. Décompresser les deux ZIP successifs, puis déplacer l'application dans Applications.

La version 0.1 est compilée par GitHub Actions sur macOS 15, pour Mac Apple Silicon. L'application n'est **pas signée avec un certificat Developer ID ni notarisée** : macOS peut demander de confirmer son ouverture via Réglages Système → Confidentialité et sécurité → Ouvrir quand même. Elle est signée localement (ad hoc) pour la cohérence de l'exécutable.

## Utilisation

1. Ouvrir un plugin dans Liberty DAW (par exemple Analog Lab V).
2. Ouvrir Liberty Plugin Artwork Creator et cliquer sur **CAPTURER UNE FENÊTRE**.
3. Choisir la fenêtre du plugin dans l'outil interactif macOS.
4. Prévisualiser, recadrer et exporter un PNG.
5. Dans Liberty DAW, sélectionner le plugin et utiliser **MINIATURES → IMPORTER PNG**.

Le glisser-déposer **sur une miniature dans Liberty DAW** n'est pas encore implémenté. L'application propose un glisser du fichier PNG vers d'autres applications qui acceptent les fichiers.

## Limites

- La capture macOS demande les autorisations de capture adéquates et peut échouer sur certaines interfaces.
- Le rendu réel d'Analog Lab V n'a pas encore été validé sur la machine de l'utilisateur.
- L'application ne contourne pas les protections de macOS, et ne garantit pas une capture pour tous les plugins.
- Ce dépôt est séparé de BSM-DAW : aucune compilation de Liberty DAW n'est déclenchée ici.
