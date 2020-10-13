# Bert(Bidirectional Encoder Representations from Transformers)

[TOC]

Bert分两方面来理解，一方面是它是怎么来的，他解决了哪些问题;另一方面是从工程化的角度，bert到底怎么用。

## bert到底是什么

bert是一个经过预训练的语言表达方法，也就是说，先通过一个很大的语料库，训练一个通用的语言理解模型，然后再用这个模型来做细分的NLP任务。bert比以往的方法都要好，因为它是第一个针对预训练NLP的无监督，深度双向系统。
bert的无监督体现在它完全是通过原始语料库训练来的，这其实非常重要，因为原始语料库在网络是非常容易获取的。

bert为了达到无监督和双向，使用了一个非常简单又巧妙的途径：屏蔽掉输入中15%的单词，然后在深度双向的transformer网络中运行整个句子，然后预测被屏蔽掉的单词。

为了能够学习句子之间的关系，也用一个简单的任务对此进行了训练，任务可以由任何单一语言语料库来生成。给定两个句子，A和B,B可能是A的下一句，也可能不是，然后进行大量的训练。

大致上，这就是bert

bert是一个经过预训练的神经网络。那么是不是可以认为，预训练的部分教会了它对语言的基本理解，剩下的是写作文，还是阅读理解，只需要根据具体任务进行fine-tuning就行了。当然预训练其实成本很高，但好处是一旦学会了就忘不掉了。

> BERT拥有一个深而窄的神经网络。transformer的中间层有2048，BERT只有1024，但却有12层。因此，它可以在无需大幅架构修改的前提下进行双向训练。由于是无监督学习，因此不需要人工干预和标注，让低成本地训练超大规模语料成为可能。
BERT模型能够联合神经网络所有层中的上下文来进行训练。这样训练出来的模型在处理问答或语言推理任务时，能够结合上下文理解语义，并且实现更精准的文本预测生成。
BERT只需要微调就可以适应很多类型的NLP任务，这使其应用场景扩大，并且降低了企业的训练成本。BERT支持包括中文在内的60种语言，研究人员也不需要从头开始训练自己的模型，只需要利用BERT针对特定任务进行修改，在单个云TPU上运行几小时甚至几十分钟，就能获得不错的分数

BERT提供了简单和复杂两个模型BERT_base和BERT_large

类型 | 网络层数(Bert Model) | 隐层大小 | Attention的数量 | 参数总大小
---|---|---|---|---
BERT_base | L=12 | H=768 | A=12 | 110MB
BERT_large | L=24 | H=1024 | A=16 | 340MB

[github地址 https://github.com/google-research/bert](https://github.com/google-research/bert)

## Bert特点

- NLP领域大有作为， 只需要微调就可以适应很多类型的NLP任务
- 使用了Transformer 作为算法的主要框架
- 开源

## 模型

```text
                               matmul
                                 ^
                                 |
                                 |
                            Pooler Dense
                                 ^
                                 |
                                 |
                    |--------------------------|
                    |        Add & Norm        |
                    |            ^             |
                    |            |             |
                    |        Feed Forward      |
                    |            ^             |
        BertModel   |            |             |   x12
                    |        Add & Norm        |
                    |            ^             |
                    |            |             |
                    |    Multi-Head Attention  |
                    |---------------------------
                                 ^
                                 |
                                 |
                            Layer Normal
                                 ^
                                 |
                                 |
 Position Embedding ----------> add <---------- Segment Embedding
                                 ^
                                 |
                                 |
                          Input Embedding

```

Bert获取前端输入的嵌入特征，然后通过Bert Model对特征进行处理，Bert Model 和 Transformer model 很相似， 最后要通过特殊处理获得想要的结果，针对不同的细分应用，后续的处理会有不同。

## forward

```plantuml
(模型输入，以MRPC为例，两句话，判定相关性) as input
note left
PCCW 's chief operating officer , Mike Butcher ,
and Alex Arena , the chief financial officer ,
will report directly to Mr So .

Current Chief Operating Officer Mike Butcher
and Group Chief Financial Officer Alex Arena
will report to So .
endnote

(FullTokenizer \n\n\
第一步通过load_vocab加载词典\n\
第二步BasicTokenizer去除空格等无意义字符，进行粗粒度分词\n\
第三步WordpieceTokenizer根据词典使用贪婪算法进行细粒度分词) as tk

(细粒度分词结果) as tokened

input --> tk
tk --> tokened
note left
[CLS] pc ##c ##w ' s chief operating officer ,
mike butcher , and alex arena , the chief
financial officer , will report directly to mr so .
[SEP] current chief operating officer mike
butcher and group chief financial officer
alex arena will report to so . [SEP]
endnote

(查找字典，获取字符编码,标记为input_ids) as InputIds
(把第一句所有字符标记为0，\n\
第二句所有字符标记为1，组成segment_ids) as SegmentIds
(强制编码句子中每个词的位置，组成position) as position
(根据句子最大编码长度，有效字符标记为1，\n\
未使用的标记为0，组成input_mask) as InputMask

tokened --> InputIds
tokened --> InputMask
tokened --> SegmentIds
tokened --> position

(Input Embedding\n\
查表) as ie
(Position Embedding) as pe
(Segment Embeddin\n\
one-hot) as se

InputIds --> ie
position --> pe
SegmentIds --> se

ie --> (add)
pe --> (add)
se --> (add)
```

BERT不直接处理单词，而是把WordPieces作为token。
BERT的输入的编码向量是3个嵌入特征的单位和，这三个词嵌入特征是：

- WordPiece 嵌入：查找WordPiece嵌入的token词汇表。用##表示分词。 WordPiece是指将单词划分成一组有限的公共子词单元，能在单词的有效性和字符的灵活性之间取得一个折中的平衡。如将‘playing’被拆分成了‘play’和‘ing’。在句子开头和结尾还会插入两个特殊符号[CLS]和[SEP]，其中[CLS]表示该特征用于分类模型，每个序列的第一个token始终是特殊分类嵌入（[CLS]）。对应于该token的最终隐藏状态（即，Transformer的输出）被用作分类任务的聚合序列表示。对于非分类任务，将忽略此向量。[SEP]表示分句符号，用于断开输入语料中的两个句子
- 位置嵌入（Position Embedding）：位置嵌入是指将单词的位置信息编码成特征向量，位置嵌入是向模型中引入单词位置关系的至关重要的一环
- 分割嵌入（Segment Embedding）：用于区分两个句子，例如B是否是A的下文（对话场景，问答场景等）。对于句子对，第一个句子的特征值是0，第二个句子的特征值是1

mask嵌入特征会在bert Model中使用，这和transformer一样

## 训练任务

Bert的训练任务可以分为Pretraining任务和Fine-Tuning。Pretraining任务实现了一个基础的Bert，在需要进行具体的任务时，还需要进行Fine-Tuning

### Pretraining任务

BERT是一个多任务模型，它的任务是由两个自监督任务组成，即MLM(Masked Language Model)和NSP(Next Sentence Prediction)

#### MLM

所谓MLM是指在训练的时候随即从输入预料上mask掉一些单词，然后通过的上下文预测该单词。在BERT的实验中，15%的WordPiece Token会被随机Mask掉。在训练模型时，一个句子会被多次喂到模型中用于参数学习，但是Google并没有在每次都mask掉这些单词，而是在确定要Mask掉的单词之后

80%时间：my dog is hairy -> my dog is [mask]
10%时间：my dog is hairy -> my dog is apple
10%时间：my dog is hairy -> my dog is hairy

#### MSP

Next Sentence Prediction（NSP）的任务是判断句子B是否是句子A的下文。如果是的话输出“IsNext”，否则输出“NotNext”。训练数据的生成方式是从平行语料中随机抽取的连续两句话，其中50%保留抽取的两句话，它们符合IsNext关系，另外50%的第二句话是随机从预料中提取的，它们的关系是NotNext的。这个关系保存在[CLS]符号中

### Fine-Tuning

在海量单预料上训练完BERT之后，便可以将其应用到NLP的各个任务中了.对于其它任务来说，我们也可以根据BERT的输出信息作出对应的预测,它们只需要在BERT的基础上再添加一个输出层便可以完成对特定任务的微调

微调的任务包括

- 基于句子对的分类任务
- 基于单个句子的分类任务
- 问答任务
- 命名实体识别

#### 基于句子对的分类任务

##### MNLI

给定一个前提 (Premise) ，根据这个前提去推断假设 (Hypothesis) 与前提的关系。该任务的关系分为三种，蕴含关系 (Entailment)、矛盾关系 (Contradiction) 以及中立关系 (Neutral)。所以这个问题本质上是一个分类问题，我们需要做的是去发掘前提和假设这两个句子对之间的交互信息

##### QQP

基于Quora，判断 Quora 上的两个问题句是否表示的是一样的意思。QNLI：用于判断文本是否包含问题的答案，类似于我们做阅读理解定位问题所在的段落。

##### STS-B

预测两个句子的相似性，包括5个级别。

##### MRPC

也是判断两个句子是否是等价的。

##### RTE

类似于MNLI，但是只是对蕴含关系的二分类判断，而且数据集更小。

##### SWAG

从四个句子中选择为可能为前句下文的那个。

#### 基于单个句子的分类任务

##### SST-2

电影评价的情感分析。

##### CoLA

句子语义判断，是否是可接受的（Acceptable）。

#### 问答任务

##### SQuAD v1.1

给定一个句子（通常是一个问题）和一段描述文本，输出这个问题的答案，类似于做阅读理解的简答题。如图 (c)表示的，SQuAD的输入是问题和描述文本的句子对。输出是特征向量，通过在描述文本上接一层激活函数为softmax的全连接来获得输出文本的条件概率，全连接的输出节点个数是语料中Token的个数

#### 命名实体识别

##### CoNLL-2003 NER

判断一个句子中的单词是不是Person，Organization，Location，Miscellaneous或者other（无命名实体）。微调CoNLL-2003 NER时将整个句子作为输入，在每个时间片输出一个概率，并通过softmax得到这个Token的实体类别。
