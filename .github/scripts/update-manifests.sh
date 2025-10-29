#!/bin/bash

set -e

ENVIRONMENT="$1"
IMAGE_TAG="$2"
GITOPS_PATH="$3"
MANIFEST_PATH="${GITOPS_PATH}/overlays/${ENVIRONMENT}"

echo "🔄 Updating image tag to: ${IMAGE_TAG} in ${MANIFEST_PATH}"

# Vérifier que le chemin existe
if [[ ! -d "${MANIFEST_PATH}" ]]; then
    echo "❌ Manifest path not found: ${MANIFEST_PATH}"
    echo "📁 Available overlays:"
    ls -la "${GITOPS_PATH}/overlays/" || echo "Overlays directory not found"
    exit 1
fi

# Mettre à jour le tag d'image dans kustomization.yaml
if [[ -f "${MANIFEST_PATH}/kustomization.yaml" ]]; then
    # Sauvegarder la version originale
    cp "${MANIFEST_PATH}/kustomization.yaml" "${MANIFEST_PATH}/kustomization.yaml.backup"
    
    # Mettre à jour le tag pour l'image banking-app
    if grep -q "tdksoft341/tdk-banking-app" "${MANIFEST_PATH}/kustomization.yaml"; then
        sed -i "s|newTag:.*|newTag: \"${IMAGE_TAG}\"|g" "${MANIFEST_PATH}/kustomization.yaml"
        echo "✅ Updated banking-app image tag to ${IMAGE_TAG}"
    else
        echo "⚠️  banking-app image not found in kustomization.yaml, adding it..."
        # Ajouter la section images si elle n'existe pas
        if ! grep -q "images:" "${MANIFEST_PATH}/kustomization.yaml"; then
            echo "" >> "${MANIFEST_PATH}/kustomization.yaml"
            echo "images:" >> "${MANIFEST_PATH}/kustomization.yaml"
        fi
        # Ajouter l'image
        echo "- name: tdksoft341/tdk-banking-app" >> "${MANIFEST_PATH}/kustomization.yaml"
        echo "  newTag: \"${IMAGE_TAG}\"" >> "${MANIFEST_PATH}/kustomization.yaml"
    fi
    
    echo "✅ Updated kustomization.yaml in ${MANIFEST_PATH}"
else
    echo "❌ kustomization.yaml not found in ${MANIFEST_PATH}"
    exit 1
fi

# Afficher les différences
echo "📄 Changes made:"
diff -u "${MANIFEST_PATH}/kustomization.yaml.backup" "${MANIFEST_PATH}/kustomization.yaml" || true

# Nettoyer la backup
rm -f "${MANIFEST_PATH}/kustomization.yaml.backup"

echo "🎯 Final kustomization.yaml:"
cat "${MANIFEST_PATH}/kustomization.yaml"