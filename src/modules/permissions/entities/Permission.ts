export class Permission {
  constructor(
    public id: number,
    public name: string,
    public description: string,
    public isMandatory: boolean
  ) {
    if (!name || !name.trim()) throw new Error("Permission name is required");
    if (!description || !description.trim()) throw new Error("Permission description is required");
    if (typeof isMandatory !== "boolean") throw new Error("isMandatory must be boolean");
  }
}
