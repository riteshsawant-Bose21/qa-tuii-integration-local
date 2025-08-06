import { deviceModels } from "../constants"
import { ModelDefinition } from "../models/model";

export function getDeviceLogo(model: string): string | undefined {
    return deviceModels.find((d: ModelDefinition) => d.model === model)?.image_url;
}