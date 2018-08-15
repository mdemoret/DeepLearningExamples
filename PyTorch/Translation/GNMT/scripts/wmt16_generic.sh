#! /usr/bin/env bash

# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

FROM_LANG=${1:-"de"}
TO_LANG=${2:-"en"}

OUTPUT_DIR=${3:-"data/wmt16_${FROM_LANG}_${TO_LANG}"}
echo "Writing to ${OUTPUT_DIR}. To change this, set the OUTPUT_DIR environment variable."

OUTPUT_DIR_DATA="${OUTPUT_DIR}/data"

mkdir -p $OUTPUT_DIR_DATA

echo "Downloading Europarl v7. This may take a while..."
wget -nc -nv -O ${OUTPUT_DIR_DATA}/europarl-v7-${FROM_LANG}-${TO_LANG}.tgz \
  http://www.statmt.org/europarl/v7/${FROM_LANG}-${TO_LANG}.tgz

echo "Downloading Common Crawl corpus. This may take a while..."
wget -nc -nv -O ${OUTPUT_DIR_DATA}/common-crawl.tgz \
  http://www.statmt.org/wmt13/training-parallel-commoncrawl.tgz

echo "Downloading News Commentary v11. This may take a while..."
wget -nc -nv -O ${OUTPUT_DIR_DATA}/nc-v11.tgz \
  http://data.statmt.org/wmt16/translation-task/training-parallel-nc-v11.tgz

echo "Downloading dev/test sets"
wget -nc -nv -O  ${OUTPUT_DIR_DATA}/dev.tgz \
  http://data.statmt.org/wmt16/translation-task/dev.tgz
wget -nc -nv -O  ${OUTPUT_DIR_DATA}/test.tgz \
  http://data.statmt.org/wmt16/translation-task/test.tgz

# Extract everything
echo "Extracting all files..."
mkdir -p "${OUTPUT_DIR_DATA}/europarl-v7-${FROM_LANG}-${TO_LANG}"
tar -xvzf "${OUTPUT_DIR_DATA}/europarl-v7-${FROM_LANG}-${TO_LANG}.tgz" -C "${OUTPUT_DIR_DATA}/europarl-v7-${FROM_LANG}-${TO_LANG}"
mkdir -p "${OUTPUT_DIR_DATA}/common-crawl"
tar -xvzf "${OUTPUT_DIR_DATA}/common-crawl.tgz" -C "${OUTPUT_DIR_DATA}/common-crawl"
mkdir -p "${OUTPUT_DIR_DATA}/nc-v11"
tar -xvzf "${OUTPUT_DIR_DATA}/nc-v11.tgz" -C "${OUTPUT_DIR_DATA}/nc-v11"
mkdir -p "${OUTPUT_DIR_DATA}/dev"
tar -xvzf "${OUTPUT_DIR_DATA}/dev.tgz" -C "${OUTPUT_DIR_DATA}/dev"
mkdir -p "${OUTPUT_DIR_DATA}/test"
tar -xvzf "${OUTPUT_DIR_DATA}/test.tgz" -C "${OUTPUT_DIR_DATA}/test"

# Concatenate Training data
cat "${OUTPUT_DIR_DATA}/europarl-v7-${FROM_LANG}-${TO_LANG}/europarl-v7.${FROM_LANG}-${TO_LANG}.${TO_LANG}" \
  "${OUTPUT_DIR_DATA}/common-crawl/commoncrawl.${FROM_LANG}-${TO_LANG}.${TO_LANG}" \
  "${OUTPUT_DIR_DATA}/nc-v11/training-parallel-nc-v11/news-commentary-v11.${FROM_LANG}-${TO_LANG}.${TO_LANG}" \
  > "${OUTPUT_DIR}/train.${TO_LANG}"
wc -l "${OUTPUT_DIR}/train.${TO_LANG}"

cat "${OUTPUT_DIR_DATA}/europarl-v7-${FROM_LANG}-${TO_LANG}/europarl-v7.${FROM_LANG}-${TO_LANG}.${FROM_LANG}" \
  "${OUTPUT_DIR_DATA}/common-crawl/commoncrawl.${FROM_LANG}-${TO_LANG}.${FROM_LANG}" \
  "${OUTPUT_DIR_DATA}/nc-v11/training-parallel-nc-v11/news-commentary-v11.${FROM_LANG}-${TO_LANG}.${FROM_LANG}" \
  > "${OUTPUT_DIR}/train.${FROM_LANG}"
wc -l "${OUTPUT_DIR}/train.${FROM_LANG}"

# Clone Moses
if [ ! -d "${OUTPUT_DIR}/mosesdecoder" ]; then
  echo "Cloning moses for data processing"
  git clone https://github.com/moses-smt/mosesdecoder.git "${OUTPUT_DIR}/mosesdecoder"
  cd ${OUTPUT_DIR}/mosesdecoder
  git reset --hard 8c5eaa1a122236bbf927bde4ec610906fea599e6
  cd -
fi

# Convert SGM files
# Convert newstest2014 data into raw text format
${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
  < ${OUTPUT_DIR_DATA}/dev/dev/newstest2014-${FROM_LANG}${TO_LANG}-src.${FROM_LANG}.sgm \
  > ${OUTPUT_DIR_DATA}/dev/dev/newstest2014.${FROM_LANG}
${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
  < ${OUTPUT_DIR_DATA}/dev/dev/newstest2014-${FROM_LANG}${TO_LANG}-ref.${TO_LANG}.sgm \
  > ${OUTPUT_DIR_DATA}/dev/dev/newstest2014.${TO_LANG}

# Convert newstest2015 data into raw text format
${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
  < ${OUTPUT_DIR_DATA}/dev/dev/newstest2015-${FROM_LANG}${TO_LANG}-src.${FROM_LANG}.sgm \
  > ${OUTPUT_DIR_DATA}/dev/dev/newstest2015.${FROM_LANG}
${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
  < ${OUTPUT_DIR_DATA}/dev/dev/newstest2015-${FROM_LANG}${TO_LANG}-ref.${TO_LANG}.sgm \
  > ${OUTPUT_DIR_DATA}/dev/dev/newstest2015.${TO_LANG}

# Convert newstest2016 data into raw text format
${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
  < ${OUTPUT_DIR_DATA}/test/test/newstest2016-${FROM_LANG}${TO_LANG}-src.${FROM_LANG}.sgm \
  > ${OUTPUT_DIR_DATA}/test/test/newstest2016.${FROM_LANG}
${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
  < ${OUTPUT_DIR_DATA}/test/test/newstest2016-${FROM_LANG}${TO_LANG}-ref.${TO_LANG}.sgm \
  > ${OUTPUT_DIR_DATA}/test/test/newstest2016.${TO_LANG}

# Copy dev/test data to output dir
cp ${OUTPUT_DIR_DATA}/dev/dev/newstest20*.${FROM_LANG} ${OUTPUT_DIR}
cp ${OUTPUT_DIR_DATA}/dev/dev/newstest20*.${TO_LANG} ${OUTPUT_DIR}
cp ${OUTPUT_DIR_DATA}/test/test/newstest20*.${FROM_LANG} ${OUTPUT_DIR}
cp ${OUTPUT_DIR_DATA}/test/test/newstest20*.${TO_LANG} ${OUTPUT_DIR}

# Tokenize data
for f in ${OUTPUT_DIR}/*.${FROM_LANG}; do
  echo "Tokenizing $f..."
  ${OUTPUT_DIR}/mosesdecoder/scripts/tokenizer/tokenizer.perl -q -l ${FROM_LANG} -threads 8 < $f > ${f%.*}.tok.${FROM_LANG}
done

for f in ${OUTPUT_DIR}/*.${TO_LANG}; do
  echo "Tokenizing $f..."
  ${OUTPUT_DIR}/mosesdecoder/scripts/tokenizer/tokenizer.perl -q -l ${TO_LANG} -threads 8 < $f > ${f%.*}.tok.${TO_LANG}
done

# Clean all corpora
for f in ${OUTPUT_DIR}/*.${TO_LANG}; do
  fbase=${f%.*}
  echo "Cleaning ${fbase}..."
  ${OUTPUT_DIR}/mosesdecoder/scripts/training/clean-corpus-n.perl $fbase ${FROM_LANG} ${TO_LANG} "${fbase}.clean" 1 80
done

# Create dev dataset
cat "${OUTPUT_DIR}/newstest2015.tok.clean.${TO_LANG}" \
   "${OUTPUT_DIR}/newstest2016.tok.clean.${TO_LANG}" \
   > "${OUTPUT_DIR}/newstest_dev.tok.clean.${TO_LANG}"

cat "${OUTPUT_DIR}/newstest2015.tok.clean.${FROM_LANG}" \
   "${OUTPUT_DIR}/newstest2016.tok.clean.${FROM_LANG}" \
   > "${OUTPUT_DIR}/newstest_dev.tok.clean.${FROM_LANG}"

# Filter datasets
python3 scripts/filter_dataset.py \
   -f1 ${OUTPUT_DIR}/train.tok.clean.${TO_LANG} \
   -f2 ${OUTPUT_DIR}/train.tok.clean.${FROM_LANG}
python3 scripts/filter_dataset.py \
   -f1 ${OUTPUT_DIR}/newstest_dev.tok.clean.${TO_LANG} \
   -f2 ${OUTPUT_DIR}/newstest_dev.tok.clean.${FROM_LANG}

# Generate Subword Units (BPE)
# Clone Subword NMT
if [ ! -d "${OUTPUT_DIR}/subword-nmt" ]; then
  git clone https://github.com/rsennrich/subword-nmt.git "${OUTPUT_DIR}/subword-nmt"
  cd ${OUTPUT_DIR}/subword-nmt
  git reset --hard 48ba99e657591c329e0003f0c6e32e493fa959ef
  cd -
fi

# Learn Shared BPE
for merge_ops in 32000; do
  echo "Learning BPE with merge_ops=${merge_ops}. This may take a while..."
  cat "${OUTPUT_DIR}/train.tok.clean.${FROM_LANG}" "${OUTPUT_DIR}/train.tok.clean.${TO_LANG}" | \
    ${OUTPUT_DIR}/subword-nmt/learn_bpe.py -s $merge_ops > "${OUTPUT_DIR}/bpe.${merge_ops}"

  echo "Apply BPE with merge_ops=${merge_ops} to tokenized files..."
  for lang in ${TO_LANG} ${FROM_LANG}; do
    for f in ${OUTPUT_DIR}/*.tok.${lang} ${OUTPUT_DIR}/*.tok.clean.${lang}; do
      outfile="${f%.*}.bpe.${merge_ops}.${lang}"
      ${OUTPUT_DIR}/subword-nmt/apply_bpe.py -c "${OUTPUT_DIR}/bpe.${merge_ops}" < $f > "${outfile}"
      echo ${outfile}
    done
  done

  # Create vocabulary file for BPE
  cat "${OUTPUT_DIR}/train.tok.clean.bpe.${merge_ops}.${TO_LANG}" "${OUTPUT_DIR}/train.tok.clean.bpe.${merge_ops}.${FROM_LANG}" | \
    ${OUTPUT_DIR}/subword-nmt/get_vocab.py | cut -f1 -d ' ' > "${OUTPUT_DIR}/vocab.bpe.${merge_ops}"

done

echo "All done."
