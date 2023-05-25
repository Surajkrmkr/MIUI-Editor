class MIUITags {
  List<Tag>? tag;

  MIUITags({this.tag});

  MIUITags.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      tag = <Tag>[];
      json['data'].forEach((v) {
        tag!.add(Tag.fromJson(v));
      });
    }
  }
}

class Tag {
  String? name;
  List<String>? subTags;

  Tag({this.name, this.subTags});

  Tag.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    subTags = json['subTags'].cast<String>();
  }
}
