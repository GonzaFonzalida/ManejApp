import { DrivingClassService } from "./services";
import { ExpressFunction } from "../shared/types/ExpressFunction";
export class DrivingClassController {
  constructor(private service: DrivingClassService) {}

create : ExpressFunction = async(req, res) => {
    const drivingClass = await this.service.create(req.body);
    res.status(201).json(drivingClass);
  }

list : ExpressFunction = async(req, res) => {
    const classes = await this.service.listClasses();
    res.json(classes);
  }

getById : ExpressFunction = async(req, res) => {
    const cls = await this.service.getClassById(Number(req.params.id));
    if (!cls) return res.status(404).json({ message: "Class not found" });
    res.json(cls);
  }

update : ExpressFunction = async(req, res) => {
    const cls = await this.service.updateClass(Number(req.params.id), req.body);
    res.json(cls);
  }

cancel : ExpressFunction = async(req, res) => {
    await this.service.cancelClass(Number(req.params.id));
    res.status(204).send();
  }

delete : ExpressFunction = async(req, res) => {
    await this.service.deleteClass(Number(req.params.id));
    res.status(204).send();
  }
}
