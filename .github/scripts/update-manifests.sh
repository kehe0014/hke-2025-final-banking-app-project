#!/bin/bash

set -e

ENVIRONMENT="$1"
IMAGE_TAG="$2"
GITOPS_PATH="$3"

echo "🔄 Starting manifest update..."
echo "Environment: $ENVIRONMENT"
echo "Image Tag: $IMAGE_TAG" 
echo "GitOps Path: $GITOPS_PATH"

MANIFEST_PATH="${GITOPS_PATH}/overlays/${ENVIRONMENT}"

echo "Target manifest path: $MANIFEST_PATH"

# Vérifier que le chemin existe
if [[ ! -d "${MANIFEST_PATH}" ]]; then
    echo "❌ Manifest path not found: ${MANIFEST_PATH}"
    echo "📁 Current directory: $(pwd)"
    echo "📁 Available overlays:"
    ls -la "${GITOPS_PATH}/overlays/" || echo "Overlays directory not found"
    exit 1
fi

# Vérifier que kustomization.yaml existe
if [[ ! -f "${MANIFEST_PATH}/kustomization.yaml" ]]; then
    echo "❌ kustomization.yaml not found in ${MANIFEST_PATH}"
    echo "📄 Files in ${MANIFEST_PATH}:"
    ls -la "${MANIFEST_PATH}" || echo "Directory not accessible"
    exit 1
fi

echo "✅ Found kustomization.yaml in ${MANIFEST_PATH}"

# Sauvegarder la version originale
cp "${MANIFEST_PATH}/kustomization.yaml" "${MANIFEST_PATH}/kustomization.yaml.backup"

# Mettre à jour le tag d'image
echo "📝 Updating image tag to: ${IMAGE_TAG}"

# Méthode 1: Utiliser sed pour remplacer newTag
if grep -q "newTag:" "${MANIFEST_PATH}/kustomization.yaml"; then
    sed -i "s|newTag:.*|newTag: \"${IMAGE_TAG}\"|g" "${MANIFEST_PATH}/kustomization.yaml"
    echo "✅ Updated image tag using sed"
else
    # Méthode 2: Ajouter la section images si elle n'existe pas
    echo "⚠️  newTag not found, adding images section..."
    if ! grep -q "images:" "${MANIFEST_PATH}/kustomization.yaml"; then
        echo "" >> "${MANIFEST_PATH}/kustomization.yaml"
        echo "images:" >> "${MANIFEST_PATH}/kustomization.yaml"
    fi
    # Ajouter l'image spécifique
    echo "- name: tdksoft341/tdk-banking-app" >> "${MANIFEST_PATH}/kustomization.yaml"
    echo "  newTag: \"${IMAGE_TAG}\"" >> "${MANIFEST_PATH}/kustomization.yaml"
    echo "✅ Added images section with new tag"
fi

# Afficher les différences
echo "📄 Changes made:"
if diff -u "${MANIFEST_PATH}/kustomization.yaml.backup" "${MANIFEST_PATH}/kustomization.yaml"; then
    echo "⚠️  No changes were made (tags were already up to date)"
else
    echo "✅ Changes applied successfully"
fi

# Nettoyer la backup
rm -f "${MANIFEST_PATH}/kustomization.yaml.backup"

echo "🎯 Final kustomization.yaml content:"
cat "${MANIFEST_PATH}/kustomization.yaml"